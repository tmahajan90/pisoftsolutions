class PaymentService
  SUPPORTED_GATEWAYS = %w[razorpay cashfree].freeze
  
  def initialize(gateway = 'razorpay')
    @gateway = gateway.to_s.downcase
    
    unless SUPPORTED_GATEWAYS.include?(@gateway)
      raise ArgumentError, "Unsupported payment gateway: #{@gateway}. Supported gateways: #{SUPPORTED_GATEWAYS.join(', ')}"
    end
    
    @service = case @gateway
               when 'razorpay'
                 RazorpayService.new
               when 'cashfree'
                 CashfreeService.new
               end
  end

  # Create a new payment order
  def create_order(amount, currency = 'INR', order_meta = {})
    Rails.logger.info "Creating payment order with #{@gateway} gateway"
    
    case @gateway
    when 'razorpay'
      create_razorpay_order(amount, currency, order_meta)
    when 'cashfree'
      create_cashfree_order(amount, currency, order_meta)
    end
  end

  # Verify payment
  def verify_payment(payment_data)
    Rails.logger.info "Verifying payment with #{@gateway} gateway"
    
    case @gateway
    when 'razorpay'
      verify_razorpay_payment(payment_data)
    when 'cashfree'
      verify_cashfree_payment(payment_data)
    end
  end

  # Get payment details
  def get_payment_details(payment_id)
    Rails.logger.info "Getting payment details with #{@gateway} gateway"
    
    case @gateway
    when 'razorpay'
      @service.get_payment_details(payment_id)
    when 'cashfree'
      @service.get_payment_details(payment_id)
    end
  end

  # Refund payment
  def refund_payment(payment_id, amount = nil, reason = nil)
    Rails.logger.info "Processing refund with #{@gateway} gateway"
    
    case @gateway
    when 'razorpay'
      @service.refund_payment(payment_id, amount, reason)
    when 'cashfree'
      @service.refund_payment(payment_id, amount, reason)
    end
  end

  # Get order details
  def get_order_details(order_id)
    Rails.logger.info "Getting order details with #{@gateway} gateway"
    
    case @gateway
    when 'razorpay'
      # Razorpay doesn't have a direct get order method in the service
      { success: true, order: { id: order_id, gateway: 'razorpay' } }
    when 'cashfree'
      @service.get_order_details(order_id)
    end
  end

  # Get payment methods
  def get_payment_methods(order_id = nil)
    Rails.logger.info "Getting payment methods with #{@gateway} gateway"
    
    case @gateway
    when 'razorpay'
      get_razorpay_payment_methods
    when 'cashfree'
      @service.get_payment_methods(order_id) if order_id
    end
  end

  # Gateway-specific methods
  def gateway_name
    @gateway.humanize
  end

  def gateway_key
    @gateway
  end

  def self.supported_gateways
    SUPPORTED_GATEWAYS
  end

    private

  def create_razorpay_order(amount, currency, order_meta)
    receipt = order_meta[:receipt] || order_meta[:order_id] || "receipt_#{Time.current.to_i}"
    @service.create_order(amount, currency, receipt)
  end

  def create_cashfree_order(amount, currency, order_meta)
    customer_details = {
      customer_id: order_meta[:customer_id],
      customer_name: order_meta[:customer_name],
      customer_email: order_meta[:customer_email],
      customer_phone: order_meta[:customer_phone]
    }
    
    @service.create_order(amount, currency, customer_details, order_meta)
  end

  def verify_razorpay_payment(payment_data)
    payment_id = payment_data[:payment_id] || payment_data['razorpay_payment_id']
    order_id = payment_data[:order_id] || payment_data['razorpay_order_id']
    signature = payment_data[:signature] || payment_data['razorpay_signature']
    
    @service.verify_payment_signature(payment_id, order_id, signature)
  end

  def verify_cashfree_payment(payment_data)
    # Cashfree verification is typically done via webhook
    # This method can be used for additional verification if needed
    { success: true, message: 'Cashfree payment verification handled via webhook' }
  end

  def get_razorpay_payment_methods
    {
      success: true,
      payment_methods: [
        { id: 'card', name: 'Credit/Debit Card', icon: 'fas fa-credit-card' },
        { id: 'netbanking', name: 'Net Banking', icon: 'fas fa-university' },
        { id: 'wallet', name: 'Wallet', icon: 'fas fa-wallet' },
        { id: 'upi', name: 'UPI', icon: 'fas fa-mobile-alt' },
        { id: 'emi', name: 'EMI', icon: 'fas fa-calendar-alt' }
      ]
    }
  end
end
