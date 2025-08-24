class CheckoutController < ApplicationController
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
        OrderItem.create!(
          order: @order,
          product: cart_item.product,
          quantity: cart_item.quantity,
          price: cart_item.validity_price || cart_item.product.price,
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
          OrderItem.create!(
            order: @order,
            product: cart_item.product,
            quantity: cart_item.quantity,
            price: cart_item.validity_price || cart_item.product.price,
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
        
        # Create Razorpay order
        Rails.logger.info "Creating Razorpay order for amount: #{@order.final_total}"
        razorpay_result = @order.create_razorpay_order
        
        Rails.logger.info "Razorpay result: #{razorpay_result}"
        
        if razorpay_result[:success]
          success = true
          Rails.logger.info "Razorpay order created successfully: #{razorpay_result[:order_id]}"
        else
          Rails.logger.error "Razorpay order creation failed: #{razorpay_result[:error]}"
          
          # For testing purposes, if Razorpay fails, create a mock order
          if Rails.env.development? && razorpay_result[:error]&.include?('Authentication failed')
            Rails.logger.info "Creating mock Razorpay order for testing"
            mock_order_id = "order_mock_#{@order.id}_#{Time.current.to_i}"
            @order.update(razorpay_order_id: mock_order_id)
            success = true
            Rails.logger.info "Mock Razorpay order created: #{mock_order_id}"
          else
            # Rollback the transaction if Razorpay order creation fails
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
      
      # Redirect to payment page with Razorpay order details
      Rails.logger.info "Redirecting to payment page: #{payment_path(@order)}"
      redirect_to payment_path(@order), notice: 'Order created successfully! Please complete the payment.'
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
    @razorpay_key = ENV['RAZORPAY_KEY_ID']
  end

  def payment_callback
    @order = Order.find(params[:id])
    razorpay_service = RazorpayService.new
    
    # Log the callback for debugging
    Rails.logger.info "Payment callback received for order #{@order.id}"
    Rails.logger.info "Payment ID: #{params[:razorpay_payment_id]}"
    Rails.logger.info "Order ID: #{params[:razorpay_order_id]}"
    
    # Check if this is a test payment
    if params[:razorpay_payment_id]&.start_with?('pay_test_') || @order.razorpay_order_id&.start_with?('order_mock_')
      Rails.logger.info "Processing test payment for order #{@order.id}"
      @order.mark_payment_successful(params[:razorpay_payment_id])
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
        @order.mark_payment_successful(params[:razorpay_payment_id])
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
  rescue => e
    Rails.logger.error "Error in payment callback for order #{params[:id]}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    if @order
      @order.mark_payment_failed
      redirect_to order_path(@order), alert: 'An error occurred during payment processing. Please contact support.'
    else
      redirect_to root_path, alert: 'An error occurred during payment processing. Please contact support.'
    end
  end
  
  private
  
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
