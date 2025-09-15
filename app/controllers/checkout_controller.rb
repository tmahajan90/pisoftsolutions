class CheckoutController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :get_or_create_cart, only: [:index, :apply_offer, :process_payment]
  before_action :load_available_offers, only: [:index]
  
  def index
    @cart_items = @cart.cart_items.includes(:product)
    @order = Order.new
    @order.user = current_user if logged_in?

    @order.user_email = current_user&.email || ''
    @order.total_amount = @cart.total_amount
    @order.status = 'pending'
    @subtotal = @cart.total_amount
    @applied_offers = []
    @total_discount = 0
    @final_total = @subtotal
  end
  
  def apply_offer
    offer = Offer.find_by(code: params[:offer_code]&.upcase)
    
    if offer.nil?
      flash.now[:error] = "Invalid offer code"
    elsif !offer.valid_for_amount?(@cart.total_amount)
      flash.now[:error] = "Offer not valid for this order amount"
    else
      # Create a temporary order to calculate discount
      @order = Order.new
      @order.user = current_user if logged_in?
      @order.user_email = current_user&.email
      @order.save(validate: false)
      
      # Add cart items to order
      @cart.cart_items.each do |cart_item|
        # Calculate the price for this order item
        item_price = if cart_item.validity_price.present? && cart_item.validity_price > 0
                      cart_item.validity_price
                    else
                      # Find the matching validity option or use default
                      validity_option = cart_item.product.validity_options.find do |option|
                        option.duration_type == cart_item.validity_type && 
                        option.duration_value == cart_item.validity_duration
                      end
                      
                      validity_option&.price || cart_item.product.default_validity_option&.price || 0
                    end
        
        OrderItem.create!(
          order: @order,
          product: cart_item.product,
          quantity: cart_item.quantity,
          price: item_price,
          validity_type: cart_item.validity_type,
          validity_duration: cart_item.validity_duration
        )
      end
      
      if @order.apply_offer(offer)
        @applied_offers = @order.applied_offers
        @total_discount = @order.total_discount
        @final_total = @order.final_total
        flash.now[:success] = "Offer applied successfully! #{offer.display_discount}"
      else
        flash.now[:error] = "Could not apply offer"
      end
      
      # Clean up temporary order
      @order.destroy
    end
    
    @cart_items = @cart.cart_items.includes(:product)
    @order = Order.new
    @order.user = current_user if logged_in?
    @order.user_email = current_user&.email
    @subtotal = @cart.total_amount
    
    render :index
  end
  
  def process_payment
    Rails.logger.info "=== PROCESS PAYMENT STARTED ==="
    Rails.logger.info "User: #{current_user&.email}"
    Rails.logger.info "Cart items count: #{@cart.cart_items.count}"
    Rails.logger.info "Cart total: #{@cart.total_amount}"
    
    # Require login only at the final payment step
    unless logged_in?
      session[:return_to] = checkout_path
      redirect_to login_path, alert: 'Please login to complete your purchase'
      return
    end
    
    # Validate cart has items
    if @cart.cart_items.empty?
      flash[:error] = "Your cart is empty. Please add items before checkout."
      redirect_to cart_path
      return
    end
    
    @order = Order.new(order_params)
    @order.user = current_user
    @order.user_email = current_user.email
    @order.total_amount = @cart.total_amount
    @order.status = 'pending'
    @order.payment_status = 'pending'
    
    Rails.logger.info "Order params: #{order_params}"
    Rails.logger.info "Order total amount: #{@order.total_amount}"
    
    # Validate the order
    unless @order.valid?
      Rails.logger.error "Order validation failed: #{@order.errors.full_messages}"
      flash[:error] = "Please fix the following errors: #{@order.errors.full_messages.join(', ')}"
      redirect_to checkout_path
      return
    end
    
    # Start transaction to ensure data consistency
    success = false
    ActiveRecord::Base.transaction do
      if @order.save
        Rails.logger.info "Order saved successfully with ID: #{@order.id}"
        
        # Create order items from cart
        @cart.cart_items.each do |cart_item|
          # Calculate the price for this order item
          item_price = if cart_item.validity_price.present? && cart_item.validity_price > 0
                        cart_item.validity_price
                      else
                        # Find the matching validity option or use default
                        validity_option = cart_item.product.validity_options.find do |option|
                          option.duration_type == cart_item.validity_type && 
                          option.duration_value == cart_item.validity_duration
                        end
                        
                        validity_option&.price || cart_item.product.default_validity_option&.price || 0
                      end
          
          Rails.logger.info "Creating order item for #{cart_item.product.name}: price=#{item_price}, validity_price=#{cart_item.validity_price}, validity_type=#{cart_item.validity_type}, validity_duration=#{cart_item.validity_duration}"
          
          OrderItem.create!(
            order: @order,
            product: cart_item.product,
            quantity: cart_item.quantity,
            price: item_price,
            validity_type: cart_item.validity_type,
            validity_duration: cart_item.validity_duration
          )
        end
        
        Rails.logger.info "Order items created: #{@order.order_items.count}"
        
        # Apply offers if any
        if params[:applied_offers].present?
          params[:applied_offers].each do |offer_id|
            offer = Offer.find(offer_id)
            @order.apply_offer(offer)
          end
          Rails.logger.info "Offers applied: #{@order.applied_offers.count}"
        end
        
        # Select payment gateway
        selected_gateway = params[:payment_gateway] || PaymentGatewayConfig.select_gateway_for_order(@order)
        Rails.logger.info "Selected payment gateway: #{selected_gateway}"
        
        # Create payment order
        Rails.logger.info "Creating payment order for amount: #{@order.final_total} with gateway: #{selected_gateway}"
        payment_result = @order.create_payment_order(selected_gateway)
        
        Rails.logger.info "Payment result: #{payment_result}"
        
        if payment_result[:success]
          success = true
          Rails.logger.info "Payment order created successfully: #{payment_result[:order_id]}"
        else
          Rails.logger.error "Payment order creation failed: #{payment_result[:error]}"
          
          # For testing purposes, if payment fails, create a mock order
          if Rails.env.development? && payment_result[:error]&.include?('Authentication failed')
            Rails.logger.info "Creating mock payment order for testing"
            mock_order_id = "order_mock_#{@order.id}_#{Time.current.to_i}"
            @order.update(
              payment_gateway: selected_gateway,
              payment_gateway_order_id: mock_order_id
            )
            success = true
            Rails.logger.info "Mock payment order created: #{mock_order_id}"
          else
            # Rollback the transaction if payment order creation fails
            raise ActiveRecord::Rollback
          end
        end
      else
        Rails.logger.error "Order save failed: #{@order.errors.full_messages}"
        raise ActiveRecord::Rollback
      end
    end
    
    if success
      # Clear the cart
      @cart.clear
      Rails.logger.info "Cart cleared successfully"
      
      # Send confirmation emails after order items are created
      @order.send_order_confirmation_email
      @order.send_admin_order_notification
      Rails.logger.info "Confirmation emails sent"
      
      # Redirect to payment page with Razorpay order details
      Rails.logger.info "Redirecting to payment page: #{payment_path(@order)}"
      redirect_to payment_path(@order), notice: 'Order created successfully! Confirmation emails have been sent. Please complete the payment here or via email.'
    else
      # Handle failure
      if @order.persisted?
        @order.destroy
        Rails.logger.info "Order destroyed due to failure"
      end
      
      flash[:error] = "Payment gateway error: Unable to create payment order. Please try again."
      redirect_to checkout_path
    end
    
    Rails.logger.info "=== PROCESS PAYMENT ENDED ==="
  end

  def payment
    @order = Order.find(params[:id])
    @selected_gateway = @order.payment_gateway || PaymentGatewayConfig.default_gateway
    
    # Get configuration for all available gateways
    @razorpay_key = ENV['RAZORPAY_KEY_ID']
    @cashfree_app_id = ENV['CASHFREE_APP_ID']
    
    # Get available payment gateways for selection
    @available_gateways = PaymentGatewayConfig.available_gateways
  end

  def payment_callback
    Rails.logger.info "Payment callback called with params: #{params.inspect}"
    Rails.logger.info "Looking for order with ID: #{params[:id]}"
    Rails.logger.info "Orders in database: #{Order.pluck(:id, :status)}"
    
    @order = Order.find(params[:id])
    Rails.logger.info "Found order: #{@order.inspect}"
    payment_gateway = @order.payment_gateway || 'razorpay'
    
    # Log the callback for debugging
    Rails.logger.info "Payment callback received for order #{@order.id} with gateway: #{payment_gateway}"
    
    # Handle callback based on payment gateway
    case payment_gateway
    when 'razorpay'
      handle_razorpay_callback
    when 'cashfree'
      handle_cashfree_callback
    else
      Rails.logger.error "Unknown payment gateway: #{payment_gateway}"
      redirect_to order_path(@order), alert: 'Unknown payment gateway. Please contact support.'
    end
  rescue => e
    Rails.logger.error "Error in payment callback for order #{params[:id]}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    if @order
      @order.mark_payment_failed
      redirect_to order_path(@order), alert: 'An error occurred during payment processing. Please contact support.'
    else
      redirect_to root_path, alert: 'Order not found. Please contact support.'
    end
  end
  
  private

  def handle_razorpay_callback
    razorpay_service = RazorpayService.new
    
    Rails.logger.info "Payment ID: #{params[:razorpay_payment_id]}"
    Rails.logger.info "Order ID: #{params[:razorpay_order_id]}"
    
    # Check if this is a test payment
    if params[:razorpay_payment_id]&.start_with?('pay_test_') || @order.payment_gateway_order_id&.start_with?('order_mock_')
      Rails.logger.info "Processing test payment for order #{@order.id}"
      @order.mark_payment_successful(params[:razorpay_payment_id], params[:razorpay_signature])
      redirect_to order_path(@order), notice: 'Test payment successful! Your order has been confirmed.'
      return
    end
    
    # Verify payment signature for real payments
    verification_result = razorpay_service.verify_payment_signature(
      params[:razorpay_payment_id],
      params[:razorpay_order_id],
      params[:razorpay_signature]
    )
    
    if verification_result[:success]
      # Get payment details from Razorpay to double-check
      payment_details = razorpay_service.get_payment_details(params[:razorpay_payment_id])
      
      if payment_details[:success] && payment_details[:payment]['status'] == 'captured'
        @order.mark_payment_successful(params[:razorpay_payment_id], params[:razorpay_signature])
        Rails.logger.info "Payment successful for order #{@order.id}"
        redirect_to order_path(@order), notice: 'Payment successful! Your order has been confirmed.'
      else
        Rails.logger.error "Payment verification failed for order #{@order.id}: Payment not captured"
        @order.mark_payment_failed
        redirect_to order_path(@order), alert: 'Payment verification failed. Please contact support.'
      end
    else
      Rails.logger.error "Payment signature verification failed for order #{@order.id}: #{verification_result[:error]}"
      @order.mark_payment_failed
      redirect_to order_path(@order), alert: 'Payment verification failed. Please contact support.'
    end
  end

  def handle_cashfree_callback
    Rails.logger.info "Starting Cashfree callback handling for order #{@order.id}"
    
    begin
      cashfree_service = CashfreeService.new
      
      Rails.logger.info "Cashfree callback params: #{params.inspect}"
      
      # For redirect callbacks, we need to get order details using the order ID
      # The payment session ID is stored in payment_gateway_order_id, but we need the actual order ID
      cashfree_order_id = "order_#{@order.id}"
      
      Rails.logger.info "Getting order details for Cashfree order ID: #{cashfree_order_id}"
      
      # Get order details from Cashfree using the order ID
      order_details = cashfree_service.get_order_details(cashfree_order_id)
    
    if order_details[:success]
      order_data = order_details[:order]
      Rails.logger.info "Cashfree order details: #{order_data.inspect}"
      
      # Check if payment was successful
      order_status = order_data['order_status']
      Rails.logger.info "Order status: #{order_status}"
      
      if order_status == 'PAID'
        # For PAID orders, we need to get the payment details separately
        # The order details don't always include the payment_id directly
        Rails.logger.info "Order is PAID, getting payment details..."
        
        # For PAID orders, use cf_order_id as payment_id
        # This is a common pattern when the payment details are not readily available
        cf_order_id = order_data['cf_order_id']
        if cf_order_id
          Rails.logger.info "Using cf_order_id as payment_id for order #{@order.id}: #{cf_order_id}"
          @order.mark_payment_successful(cf_order_id, nil)
          redirect_to order_path(@order), notice: 'Payment successful! Your order has been confirmed.'
        else
          Rails.logger.error "cf_order_id not found in order details for order #{@order.id}"
          @order.mark_payment_failed
          redirect_to order_path(@order), alert: 'Payment verification failed. Please contact support.'
        end
      elsif order_status == 'ACTIVE'
        # Order is active but payment not yet completed
        Rails.logger.info "Order is ACTIVE - payment session created but payment not completed"
        Rails.logger.info "User will need to complete payment on Cashfree's hosted page"
        
        # Redirect back to payment page to complete the payment
        redirect_to payment_path(@order), alert: 'Please complete your payment to proceed.'
      elsif order_status == 'EXPIRED'
        Rails.logger.info "Order is EXPIRED - payment session has expired"
        @order.mark_payment_failed
        redirect_to payment_path(@order), alert: 'Payment session has expired. Please try again.'
      elsif order_status == 'CANCELLED'
        Rails.logger.info "Order is CANCELLED - payment was cancelled"
        @order.mark_payment_failed
        redirect_to payment_path(@order), alert: 'Payment was cancelled. Please try again.'
      else
        Rails.logger.error "Unknown order status for order #{@order.id}: #{order_status}"
        @order.mark_payment_failed
        redirect_to order_path(@order), alert: 'Payment status unknown. Please contact support.'
      end
    else
      Rails.logger.error "Failed to get order details from Cashfree: #{order_details[:error]}"
      @order.mark_payment_failed
      redirect_to order_path(@order), alert: 'Payment verification failed. Please contact support.'
    end
    
    rescue => e
      Rails.logger.error "Error in handle_cashfree_callback: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      @order.mark_payment_failed
      redirect_to order_path(@order), alert: 'An error occurred during payment processing. Please contact support.'
    end
  end
  
  def order_params
    params.require(:order).permit(:user_email)
  end
  
  def get_or_create_cart
    session_id = session.id.to_s
    @cart = Cart.find_or_create_by(session_id: session_id)
    
    # If user is logged in, associate the cart with them
    if current_user && @cart.user_id.nil?
      @cart.update(user_id: current_user.id)
    end
  end
  
  def load_available_offers
    @available_offers = Offer.available
  end
end
