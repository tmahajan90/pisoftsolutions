# Payment Gateways Configuration
# This file configures multiple payment gateways for the application

Rails.application.configure do
  # Payment Gateway Settings
  config.payment_gateways = {
    cashfree: {
      name: 'Cashfree',
      key: 'cashfree',
      enabled: ENV['CASHFREE_APP_ID'].present? && ENV['CASHFREE_SECRET_KEY'].present?,
      environment: ENV['CASHFREE_ENVIRONMENT'] || 'sandbox',
      app_id: ENV['CASHFREE_APP_ID'],
      secret_key: ENV['CASHFREE_SECRET_KEY'],
      webhook_secret: ENV['CASHFREE_WEBHOOK_SECRET'],
      supported_methods: %w[card netbanking wallet upi],
      features: {
        refunds: true,
        partial_refunds: true,
        recurring_payments: true,
        international_payments: false,
        currency: 'INR'
      }
    }
  }

  # Default payment gateway
  config.default_payment_gateway = ENV['DEFAULT_PAYMENT_GATEWAY'] || 'cashfree'

  # Payment gateway selection logic
  config.payment_gateway_selection = {
    # Priority order for gateway selection
    priority: %w[razorpay cashfree],
    
    # Gateway-specific rules
    rules: {
      # Use specific gateway for certain conditions
      amount_threshold: {
        cashfree: 10000, # Use Cashfree for amounts above 10,000
        razorpay: 0      # Use Razorpay for all amounts
      },
      
      # User preference
      user_preference: true, # Allow users to choose gateway
      
      # Fallback gateway
      fallback: 'razorpay'
    }
  }
end

# PaymentGatewayConfig class definition
class PaymentGatewayConfig
  # SUPPORTED_GATEWAYS = %w[razorpay cashfree].freeze
  SUPPORTED_GATEWAYS = %w[cashfree].freeze

  def self.available_gateways
    Rails.application.config.payment_gateways.select { |_, config| config[:enabled] }
  end

  def self.default_gateway
    default = Rails.application.config.default_payment_gateway
    available_gateways.key?(default.to_sym) ? default : available_gateways.keys.first.to_s
  end

  def self.gateway_config(gateway)
    Rails.application.config.payment_gateways[gateway.to_sym]
  end

  def self.supported_methods(gateway)
    config = gateway_config(gateway)
    config ? config[:supported_methods] : []
  end

  def self.gateway_features(gateway)
    config = gateway_config(gateway)
    config ? config[:features] : {}
  end

  def self.select_gateway_for_order(order)
    rules = Rails.application.config.payment_gateway_selection[:rules]
    priority = Rails.application.config.payment_gateway_selection[:priority]
    
    # Check amount threshold
    if rules[:amount_threshold]
      rules[:amount_threshold].each do |gateway, threshold|
        if order.final_total >= threshold && available_gateways.key?(gateway.to_sym)
          return gateway.to_s
        end
      end
    end
    
    # Use priority order
    priority.each do |gateway|
      if available_gateways.key?(gateway.to_sym)
        return gateway
      end
    end
    
    # Fallback
    rules[:fallback] || default_gateway
  end

  def self.supported_gateways
    SUPPORTED_GATEWAYS
  end
end
