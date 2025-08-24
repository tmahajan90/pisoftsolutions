require 'razorpay'

class RazorpayService
  def initialize
    # No need to initialize client in new API
    Rails.logger.info "RazorpayService initialized successfully"
    Rails.logger.info "Razorpay Key ID: #{ENV['RAZORPAY_KEY_ID']}"
    Rails.logger.info "Razorpay Key Secret: #{ENV['RAZORPAY_KEY_SECRET'] ? 'Present' : 'Missing'}"
  end

  # Create a new payment order
  def create_order(amount, currency = 'INR', receipt = nil)
    Rails.logger.info "Creating Razorpay order with amount: #{amount}, currency: #{currency}, receipt: #{receipt}"
    
    # Validate amount
    if amount <= 0
      Rails.logger.error "Invalid amount: #{amount}"
      return {
        success: false,
        error: "Invalid amount: #{amount}"
      }
    end
    
    order_data = {
      amount: (amount * 100).to_i, # Convert to paise
      currency: currency,
      receipt: receipt || "receipt_#{Time.current.to_i}",
      payment_capture: 1
    }

    Rails.logger.info "Order data: #{order_data}"

    begin
      Rails.logger.info "Calling Razorpay::Order.create with data: #{order_data}"
      response = Razorpay::Order.create(order_data)
      Rails.logger.info "Razorpay order created successfully: #{response['id']}"
      Rails.logger.info "Razorpay response: #{response}"
      {
        success: true,
        order_id: response['id'],
        amount: response['amount'],
        currency: response['currency'],
        receipt: response['receipt']
      }
    rescue Razorpay::Error => e
      Rails.logger.error "Razorpay error: #{e.message}"
      Rails.logger.error "Razorpay error class: #{e.class}"
      {
        success: false,
        error: e.message
      }
    rescue => e
      Rails.logger.error "Unexpected error in create_order: #{e.class} - #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
      {
        success: false,
        error: e.message
      }
    end
  end

  # Verify payment signature
  def verify_payment_signature(payment_id, order_id, signature)
    begin
      payment_response = {
        'razorpay_payment_id' => payment_id,
        'razorpay_order_id' => order_id,
        'razorpay_signature' => signature
      }
      Razorpay::Utility.verify_payment_signature(payment_response)
      { success: true }
    rescue Razorpay::Error => e
      { success: false, error: e.message }
    end
  end

  # Get payment details
  def get_payment_details(payment_id)
    begin
      payment = Razorpay::Payment.fetch(payment_id)
      {
        success: true,
        payment: payment
      }
    rescue Razorpay::Error => e
      {
        success: false,
        error: e.message
      }
    end
  end

  # Refund payment
  def refund_payment(payment_id, amount = nil, reason = nil)
    refund_data = {}
    refund_data[:amount] = (amount * 100).to_i if amount
    refund_data[:reason] = reason if reason

    begin
      response = Razorpay::Payment.refund(payment_id, refund_data)
      {
        success: true,
        refund_id: response['id'],
        amount: response['amount'],
        status: response['status']
      }
    rescue Razorpay::Error => e
      {
        success: false,
        error: e.message
      }
    end
  end
end
