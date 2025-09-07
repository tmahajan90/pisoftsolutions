# Multiple Payment Gateways Integration

This document describes the implementation of multiple payment gateways (Razorpay and Cashfree) in your Rails application.

## 🚀 Overview

The application now supports multiple payment gateways with a unified interface, allowing users to choose their preferred payment method and providing fallback options for better payment success rates.

## 🏗️ Architecture

### Core Components

1. **PaymentService** - Unified service for handling multiple payment gateways
2. **RazorpayService** - Razorpay-specific payment operations
3. **CashfreeService** - Cashfree-specific payment operations
4. **PaymentGatewayConfig** - Configuration management for payment gateways
5. **Order Model** - Updated to support multiple payment gateways

### Database Schema

```sql
-- Orders table with payment gateway support
ALTER TABLE orders ADD COLUMN payment_gateway VARCHAR DEFAULT 'razorpay';
ALTER TABLE orders ADD COLUMN payment_gateway_order_id VARCHAR;
ALTER TABLE orders ADD COLUMN payment_gateway_payment_id VARCHAR;
ALTER TABLE orders ADD COLUMN payment_gateway_signature TEXT;

-- Indexes for performance
CREATE INDEX index_orders_on_payment_gateway ON orders(payment_gateway);
CREATE INDEX index_orders_on_payment_gateway_order_id ON orders(payment_gateway_order_id);
CREATE INDEX index_orders_on_payment_gateway_payment_id ON orders(payment_gateway_payment_id);
```

## 🔧 Configuration

### Environment Variables

#### Razorpay Configuration
```bash
# Razorpay API Keys
RAZORPAY_KEY_ID=rzp_test_your_key_id
RAZORPAY_KEY_SECRET=your_secret_key
RAZORPAY_ENVIRONMENT=test  # or 'production'
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret
```

#### Cashfree Configuration
```bash
# Cashfree API Keys
CASHFREE_APP_ID=your_app_id
CASHFREE_SECRET_KEY=your_secret_key
CASHFREE_ENVIRONMENT=sandbox  # or 'production'
CASHFREE_WEBHOOK_SECRET=your_webhook_secret
```

#### General Configuration
```bash
# Base URL for callbacks
BASE_URL=https://yourdomain.com

# Default payment gateway
DEFAULT_PAYMENT_GATEWAY=razorpay
```

### Payment Gateway Configuration

The configuration is managed in `config/initializers/payment_gateways.rb`:

```ruby
config.payment_gateways = {
  razorpay: {
    name: 'Razorpay',
    key: 'razorpay',
    enabled: true,
    environment: 'test',
    supported_methods: %w[card netbanking wallet upi emi],
    features: {
      refunds: true,
      partial_refunds: true,
      recurring_payments: true,
      international_payments: false,
      currency: 'INR'
    }
  },
  cashfree: {
    name: 'Cashfree',
    key: 'cashfree',
    enabled: true,
    environment: 'sandbox',
    supported_methods: %w[card netbanking wallet upi emi],
    features: {
      refunds: true,
      partial_refunds: true,
      recurring_payments: true,
      international_payments: false,
      currency: 'INR'
    }
  }
}
```

## 💳 Supported Payment Gateways

### 1. Razorpay
- **Website**: https://razorpay.com
- **Features**: Cards, Net Banking, UPI, Wallets, EMI
- **Currencies**: INR
- **Refunds**: Full and partial refunds supported
- **Recurring**: Subscription payments supported

### 2. Cashfree
- **Website**: https://cashfree.com
- **Features**: Cards, Net Banking, UPI, Wallets, EMI
- **Currencies**: INR
- **Refunds**: Full and partial refunds supported
- **Recurring**: Subscription payments supported

## 🔄 Payment Flow

### 1. Order Creation
```ruby
# Create order with selected payment gateway
order = Order.create!(order_params)
selected_gateway = params[:payment_gateway] || PaymentGatewayConfig.select_gateway_for_order(order)
payment_result = order.create_payment_order(selected_gateway)
```

### 2. Payment Processing
```ruby
# Unified payment service
payment_service = PaymentService.new(gateway)
result = payment_service.create_order(amount, currency, order_meta)
```

### 3. Payment Verification
```ruby
# Gateway-specific verification
case order.payment_gateway
when 'razorpay'
  razorpay_service.verify_payment_signature(payment_id, order_id, signature)
when 'cashfree'
  cashfree_service.verify_webhook_signature(payload, signature)
end
```

## 🛠️ Usage Examples

### Creating a Payment Order

```ruby
# Using unified PaymentService
payment_service = PaymentService.new('razorpay')
result = payment_service.create_order(1000, 'INR', {
  order_id: "order_123",
  customer_name: "John Doe",
  customer_email: "john@example.com",
  customer_phone: "9999999999"
})

if result[:success]
  puts "Order created: #{result[:order_id]}"
else
  puts "Error: #{result[:error]}"
end
```

### Processing Payment Callback

```ruby
# In controller
def payment_callback
  @order = Order.find(params[:id])
  payment_gateway = @order.payment_gateway
  
  case payment_gateway
  when 'razorpay'
    handle_razorpay_callback
  when 'cashfree'
    handle_cashfree_callback
  end
end
```

### Refunding a Payment

```ruby
# Using unified service
payment_service = PaymentService.new('razorpay')
result = payment_service.refund_payment(payment_id, amount, reason)

if result[:success]
  puts "Refund processed: #{result[:refund_id]}"
else
  puts "Refund failed: #{result[:error]}"
end
```

## 🎯 Gateway Selection Logic

### Automatic Selection
The system automatically selects the best payment gateway based on:

1. **Amount Threshold**: Different gateways for different amounts
2. **User Preference**: User can choose their preferred gateway
3. **Gateway Availability**: Only enabled gateways are considered
4. **Fallback**: Default gateway if others fail

### Configuration Example
```ruby
config.payment_gateway_selection = {
  priority: %w[razorpay cashfree],
  rules: {
    amount_threshold: {
      cashfree: 10000,  # Use Cashfree for amounts above 10,000
      razorpay: 0       # Use Razorpay for all amounts
    },
    user_preference: true,
    fallback: 'razorpay'
  }
}
```

## 🔒 Security Features

### 1. Signature Verification
- **Razorpay**: Uses HMAC SHA256 signature verification
- **Cashfree**: Uses webhook signature verification

### 2. Webhook Security
- All webhooks are verified using gateway-specific signatures
- Invalid signatures are rejected immediately

### 3. Environment Separation
- Test and production environments are completely separate
- Different API keys for different environments

## 📊 Monitoring and Logging

### Payment Logging
All payment operations are logged with:
- Gateway used
- Amount and currency
- Order details
- Success/failure status
- Error messages

### Example Log Entry
```
[INFO] Creating payment order for amount: 1000.0 with gateway: razorpay
[INFO] Payment order created successfully: order_abc123
[INFO] Payment successful for order 123
```

## 🧪 Testing

### Test Cards

#### Razorpay Test Cards
- **Card Number**: 4111 1111 1111 1111
- **Expiry**: Any future date
- **CVV**: Any 3 digits
- **UPI ID**: success@razorpay

#### Cashfree Test Cards
- **Card Number**: 4111 1111 1111 1111
- **Expiry**: Any future date
- **CVV**: Any 3 digits
- **UPI ID**: success@cashfree

### Test Environment Setup
```bash
# Set test environment variables
RAZORPAY_ENVIRONMENT=test
CASHFREE_ENVIRONMENT=sandbox

# Use test API keys
RAZORPAY_KEY_ID=rzp_test_your_test_key
CASHFREE_APP_ID=your_test_app_id
```

## 🚨 Error Handling

### Common Error Scenarios

1. **Gateway Unavailable**
   - Automatic fallback to alternative gateway
   - User notification about gateway switch

2. **Payment Failure**
   - Detailed error logging
   - User-friendly error messages
   - Retry mechanism

3. **Signature Verification Failure**
   - Security alert logging
   - Payment marked as failed
   - Manual review required

### Error Response Format
```ruby
{
  success: false,
  error: "Payment gateway error: Unable to create payment order",
  gateway: "razorpay",
  order_id: "order_123",
  timestamp: "2024-01-01T12:00:00Z"
}
```

## 🔄 Migration Guide

### From Single Gateway to Multiple Gateways

1. **Run Migration**
   ```bash
   rails db:migrate
   ```

2. **Update Existing Orders**
   ```ruby
   # Set default gateway for existing orders
   Order.where(payment_gateway: nil).update_all(payment_gateway: 'razorpay')
   ```

3. **Update Environment Variables**
   ```bash
   # Add Cashfree configuration
   CASHFREE_APP_ID=your_app_id
   CASHFREE_SECRET_KEY=your_secret_key
   CASHFREE_ENVIRONMENT=sandbox
   ```

4. **Test Integration**
   ```bash
   # Test both gateways
   rails console
   PaymentService.new('razorpay').create_order(100, 'INR')
   PaymentService.new('cashfree').create_order(100, 'INR')
   ```

## 📈 Performance Optimization

### 1. Gateway Selection
- Cache gateway availability status
- Use connection pooling for API calls
- Implement circuit breaker pattern

### 2. Database Optimization
- Index payment gateway fields
- Use read replicas for payment queries
- Archive old payment data

### 3. API Optimization
- Implement retry logic with exponential backoff
- Use async processing for non-critical operations
- Cache gateway configurations

## 🔮 Future Enhancements

### Planned Features
1. **More Payment Gateways**: PayU, Paytm, Stripe
2. **International Payments**: Multi-currency support
3. **Advanced Analytics**: Payment success rates by gateway
4. **A/B Testing**: Gateway performance comparison
5. **Smart Routing**: AI-based gateway selection

### Integration Roadmap
1. **Phase 1**: Razorpay + Cashfree (Current)
2. **Phase 2**: Add PayU integration
3. **Phase 3**: Add international gateways
4. **Phase 4**: Advanced analytics and optimization

## 📞 Support

### Documentation Links
- [Razorpay Documentation](https://razorpay.com/docs/)
- [Cashfree Documentation](https://docs.cashfree.com/)

### Common Issues
1. **API Key Issues**: Verify environment variables
2. **Signature Verification**: Check webhook secrets
3. **Callback Issues**: Verify callback URLs
4. **Test Mode**: Ensure using test API keys

### Getting Help
- Check application logs for detailed error messages
- Verify gateway-specific documentation
- Test with provided test cards
- Contact gateway support for API issues

This implementation provides a robust, scalable foundation for handling multiple payment gateways while maintaining security and providing excellent user experience.
