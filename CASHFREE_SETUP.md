# Cashfree Payment Gateway Setup

This guide explains how to set up Cashfree as an additional payment gateway alongside Razorpay.

## 🚀 Quick Setup

### 1. Get Cashfree API Credentials

1. **Sign up for Cashfree**: Visit [https://cashfree.com](https://cashfree.com)
2. **Create an account** and complete verification
3. **Get API credentials** from the dashboard:
   - App ID
   - Secret Key
   - Webhook Secret (optional but recommended)

### 2. Environment Variables

Add these to your `.env` file:

```bash
# Cashfree Configuration
CASHFREE_APP_ID=your_app_id_here
CASHFREE_SECRET_KEY=your_secret_key_here
CASHFREE_ENVIRONMENT=sandbox  # or 'production'
CASHFREE_WEBHOOK_SECRET=your_webhook_secret_here

# Base URL for callbacks
BASE_URL=https://pisoftsolutions.com
```

### 3. Test the Integration

```bash
# Test if Cashfree is available
rails runner "puts PaymentGatewayConfig.available_gateways.keys"

# Should output: razorpay, cashfree
```

## 🧪 Testing

### Test Cards (Sandbox Mode)
- **Card Number**: 4111 1111 1111 1111
- **Expiry**: Any future date
- **CVV**: Any 3 digits
- **Name**: Any name

### Test UPI
- **UPI ID**: success@cashfree

## 🔧 Configuration

### Gateway Selection Rules

The system automatically selects payment gateways based on:

1. **Amount Threshold**: Use Cashfree for amounts above ₹10,000
2. **User Preference**: Users can choose their preferred gateway
3. **Availability**: Only enabled gateways are considered
4. **Fallback**: Default to Razorpay if others fail

### Customize Selection Rules

Edit `config/initializers/payment_gateways.rb`:

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

## 📊 Monitoring

### Check Gateway Status

```bash
# Check available gateways
rails runner "puts PaymentGatewayConfig.available_gateways"

# Check gateway configuration
rails runner "puts PaymentGatewayConfig.gateway_config('cashfree')"
```

### Logs

All payment operations are logged with:
- Gateway used
- Amount and currency
- Success/failure status
- Error messages

## 🚨 Troubleshooting

### Common Issues

1. **"Cashfree not available"**
   - Check if environment variables are set
   - Verify API credentials are correct
   - Ensure environment is set to 'sandbox' for testing

2. **"Payment creation failed"**
   - Check API credentials
   - Verify callback URLs are accessible
   - Check network connectivity

3. **"Signature verification failed"**
   - Verify webhook secret is correct
   - Check if callback URL is accessible
   - Ensure proper signature generation

### Debug Mode

Enable debug logging in `config/environments/development.rb`:

```ruby
config.log_level = :debug
```

## 🔒 Security

### Webhook Security

1. **Set webhook secret** in environment variables
2. **Verify signatures** in all webhook callbacks
3. **Use HTTPS** for all callback URLs
4. **Validate payload** before processing

### API Security

1. **Keep API keys secure** - never commit to version control
2. **Use environment variables** for all sensitive data
3. **Rotate keys regularly** for production
4. **Monitor API usage** for suspicious activity

## 📈 Production Setup

### 1. Switch to Production Mode

```bash
CASHFREE_ENVIRONMENT=production
CASHFREE_APP_ID=your_live_app_id
CASHFREE_SECRET_KEY=your_live_secret_key
```

### 2. Set Up Webhooks

Configure webhook URLs in Cashfree dashboard:
- **Success URL**: `https://pisoftsolutions.com/payment/cashfree/callback/{order_id}`
- **Failure URL**: `https://pisoftsolutions.com/payment/cashfree/callback/{order_id}`
- **Webhook URL**: `https://pisoftsolutions.com/payment/cashfree/webhook`

### 3. Test Production Integration

1. Use real payment methods (not test cards)
2. Test with small amounts first
3. Verify webhook callbacks
4. Check payment confirmations

## 🎯 Best Practices

### 1. Gateway Selection
- Use Cashfree for high-value transactions
- Use Razorpay for standard transactions
- Allow users to choose their preferred gateway

### 2. Error Handling
- Implement proper fallback mechanisms
- Log all payment failures
- Provide clear error messages to users

### 3. Monitoring
- Track payment success rates by gateway
- Monitor API response times
- Set up alerts for payment failures

### 4. Testing
- Test both gateways thoroughly
- Use test cards for development
- Verify webhook handling

## 📞 Support

### Cashfree Support
- **Documentation**: [https://docs.cashfree.com](https://docs.cashfree.com)
- **Support**: Contact through Cashfree dashboard
- **Status Page**: [https://status.cashfree.com](https://status.cashfree.com)

### Application Support
- Check application logs for detailed error messages
- Verify environment variables are set correctly
- Test with provided test cards
- Contact development team for integration issues

## 🔄 Migration from Single Gateway

If you're migrating from a single gateway setup:

1. **Run migration**: `rails db:migrate`
2. **Set environment variables** for Cashfree
3. **Test integration** with test cards
4. **Configure webhooks** in Cashfree dashboard
5. **Update payment flows** to support multiple gateways
6. **Monitor performance** and optimize selection rules

This setup provides a robust, scalable payment system with multiple gateway support for better payment success rates and user experience.
