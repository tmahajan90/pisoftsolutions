require 'net/http'
require 'uri'
require 'json'

class CashfreeService
  BASE_URL = 'https://api.cashfree.com/pg'
  SANDBOX_URL = 'https://sandbox.cashfree.com/pg'
  
  def initialize
    @app_id = ENV['CASHFREE_APP_ID']
    @secret_key = ENV['CASHFREE_SECRET_KEY']
    @environment = ENV['CASHFREE_ENVIRONMENT'] || 'sandbox'
    @base_url = @environment == 'production' ? BASE_URL : SANDBOX_URL
    
    Rails.logger.info "CashfreeService initialized successfully"
    Rails.logger.info "Cashfree App ID: #{@app_id}"
    Rails.logger.info "Cashfree Environment: #{@environment}"
    Rails.logger.info "Cashfree Secret Key: #{@secret_key ? 'Present' : 'Missing'}"
  end

  # Create a new payment order
  def create_order(amount, currency = 'INR', customer_details = {}, order_meta = {})
    Rails.logger.info "Creating Cashfree order with amount: #{amount}, currency: #{currency}"
    
    # Validate amount
    if amount <= 0
      Rails.logger.error "Invalid amount: #{amount}"
      return {
        success: false,
        error: "Invalid amount: #{amount}"
      }
    end

    order_data = {
      order_id: order_meta[:order_id]&.to_s || "order_#{Time.current.to_i}",
      order_amount: amount,
      order_currency: currency,
      customer_details: {
        customer_id: customer_details[:customer_id]&.to_s || "customer_#{Time.current.to_i}",
        customer_name: customer_details[:customer_name] || "Customer",
        customer_email: customer_details[:customer_email] || "customer@example.com",
        customer_phone: format_phone_number(customer_details[:customer_phone]) || "9999999999"
      },
      order_meta: {
        return_url: order_meta[:return_url] || build_full_url("/payment/cashfree/callback"),
        notify_url: order_meta[:notify_url] || build_full_url("/payment/cashfree/webhook")
      }
    }
    
    Rails.logger.info "Cashfree order data: #{order_data}"

    begin
      response = make_request('POST', '/orders', order_data)
      
      if response[:success]
        Rails.logger.info "Cashfree order created successfully: #{response[:data]['order_id']}"
        {
          success: true,
          order_id: response[:data]['order_id'],
          payment_session_id: response[:data]['payment_session_id'],
          amount: response[:data]['order_amount'],
          currency: response[:data]['order_currency']
        }
      else
        Rails.logger.error "Cashfree order creation failed: #{response[:error]}"
        {
          success: false,
          error: response[:error]
        }
      end
    rescue => e
      Rails.logger.error "Unexpected error in create_order: #{e.class} - #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
      {
        success: false,
        error: e.message
      }
    end
  end

  # Get order details
  def get_order_details(order_id)
    Rails.logger.info "Fetching Cashfree order details for: #{order_id}"
    
    begin
      response = make_request('GET', "/orders/#{order_id}")
      
      if response[:success]
        Rails.logger.info "Cashfree order details fetched successfully"
        {
          success: true,
          order: response[:data]
        }
      else
        Rails.logger.error "Failed to fetch Cashfree order details: #{response[:error]}"
        {
          success: false,
          error: response[:error]
        }
      end
    rescue => e
      Rails.logger.error "Unexpected error in get_order_details: #{e.class} - #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end

  # Get payment details
  def get_payment_details(payment_id)
    Rails.logger.info "Fetching Cashfree payment details for: #{payment_id}"
    
    begin
      response = make_request('GET', "/payments/#{payment_id}")
      
      if response[:success]
        Rails.logger.info "Cashfree payment details fetched successfully"
        {
          success: true,
          payment: response[:data]
        }
      else
        Rails.logger.error "Failed to fetch Cashfree payment details: #{response[:error]}"
        {
          success: false,
          error: response[:error]
        }
      end
    rescue => e
      Rails.logger.error "Unexpected error in get_payment_details: #{e.class} - #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end

  # Refund payment
  def refund_payment(payment_id, amount = nil, reason = nil)
    Rails.logger.info "Processing Cashfree refund for payment: #{payment_id}"
    
    refund_data = {
      refund_amount: amount,
      refund_note: reason || "Refund requested"
    }

    begin
      response = make_request('POST', "/payments/#{payment_id}/refund", refund_data)
      
      if response[:success]
        Rails.logger.info "Cashfree refund processed successfully: #{response[:data]['refund_id']}"
        {
          success: true,
          refund_id: response[:data]['refund_id'],
          amount: response[:data]['refund_amount'],
          status: response[:data]['refund_status']
        }
      else
        Rails.logger.error "Cashfree refund failed: #{response[:error]}"
        {
          success: false,
          error: response[:error]
        }
      end
    rescue => e
      Rails.logger.error "Unexpected error in refund_payment: #{e.class} - #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end

  # Verify webhook signature
  def verify_webhook_signature(payload, signature)
    Rails.logger.info "Verifying Cashfree webhook signature"
    
    begin
      # Cashfree webhook signature verification
      expected_signature = generate_signature(payload)
      
      if signature == expected_signature
        Rails.logger.info "Cashfree webhook signature verified successfully"
        { success: true }
      else
        Rails.logger.error "Cashfree webhook signature verification failed"
        { success: false, error: "Invalid signature" }
      end
    rescue => e
      Rails.logger.error "Error verifying Cashfree webhook signature: #{e.message}"
      { success: false, error: e.message }
    end
  end

  # Get payment methods
  def get_payment_methods(order_id)
    Rails.logger.info "Fetching Cashfree payment methods for order: #{order_id}"
    
    begin
      response = make_request('GET', "/orders/#{order_id}/payment-methods")
      
      if response[:success]
        Rails.logger.info "Cashfree payment methods fetched successfully"
        {
          success: true,
          payment_methods: response[:data]
        }
      else
        Rails.logger.error "Failed to fetch Cashfree payment methods: #{response[:error]}"
        {
          success: false,
          error: response[:error]
        }
      end
    rescue => e
      Rails.logger.error "Unexpected error in get_payment_methods: #{e.class} - #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end

  private

  def make_request(method, endpoint, data = nil)
    uri = URI("#{@base_url}#{endpoint}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    case method.upcase
    when 'GET'
      request = Net::HTTP::Get.new(uri)
    when 'POST'
      request = Net::HTTP::Post.new(uri)
      request.body = data.to_json if data
      request['Content-Type'] = 'application/json'
    when 'PUT'
      request = Net::HTTP::Put.new(uri)
      request.body = data.to_json if data
      request['Content-Type'] = 'application/json'
    end

    # Add authentication headers
    request['x-api-version'] = '2023-08-01'
    request['x-client-id'] = @app_id
    request['x-client-secret'] = @secret_key

    Rails.logger.info "Making #{method} request to: #{uri}"
    Rails.logger.info "Request headers: #{request.to_hash}"
    Rails.logger.info "Request body: #{request.body}" if request.body

    response = http.request(request)
    
    Rails.logger.info "Response status: #{response.code}"
    Rails.logger.info "Response body: #{response.body}"

    if response.code.to_i >= 200 && response.code.to_i < 300
      {
        success: true,
        data: JSON.parse(response.body)
      }
    else
      error_data = JSON.parse(response.body) rescue { 'message' => response.body }
      {
        success: false,
        error: error_data['message'] || "HTTP #{response.code}"
      }
    end
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parsing error: #{e.message}"
    {
      success: false,
      error: "Invalid JSON response"
    }
  rescue => e
    Rails.logger.error "Request error: #{e.message}"
    {
      success: false,
      error: e.message
    }
  end

  private

  def build_full_url(path)
    # Try to get the base URL from environment or construct it
    if ENV['BASE_URL'].present?
      base_url = ENV['BASE_URL']
    else
      # For Docker environments, use the host from the request or default
      host = ENV['HOST'] || 'localhost:3000'
      base_url = Rails.application.routes.url_helpers.root_url(host: host)
    end
    
    base_url = base_url.chomp('/') # Remove trailing slash if present
    path = path.start_with?('/') ? path : "/#{path}" # Ensure path starts with /
    "#{base_url}#{path}"
  end

  def format_phone_number(phone)
    return nil if phone.blank?
    
    # Remove all non-digit characters except +
    cleaned_phone = phone.gsub(/[^\d+]/, '')
    
    # Handle different formats
    if cleaned_phone.start_with?('+91')
      # Convert +91-9988915210 to +9199988915210
      cleaned_phone.gsub('+91', '+91')
    elsif cleaned_phone.start_with?('91') && cleaned_phone.length == 12
      # Convert 9199988915210 to +9199988915210
      "+#{cleaned_phone}"
    elsif cleaned_phone.start_with?('9') && cleaned_phone.length == 10
      # Convert 9988915210 to +9199988915210
      "+91#{cleaned_phone}"
    elsif cleaned_phone.start_with?('+') && cleaned_phone.length >= 10
      # Already in international format
      cleaned_phone
    else
      # Default to Indian format if unclear
      "+91#{cleaned_phone.gsub(/[^\d]/, '')}"
    end
  end

  def generate_signature(payload)
    # Cashfree webhook signature generation
    # This is a simplified version - you should implement according to Cashfree's documentation
    require 'digest'
    Digest::SHA256.hexdigest(payload + @secret_key)
  end
end
