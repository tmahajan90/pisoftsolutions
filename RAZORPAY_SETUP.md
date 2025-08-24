# Razorpay Setup Guide

## Prerequisites
1. Razorpay account (sign up at https://razorpay.com)
2. Test API keys for development
3. Live API keys for production

## Environment Variables Setup

Add these environment variables to your `.env` file or set them in your deployment environment:

### Development (Test Mode)
```bash
RAZORPAY_KEY_ID=rzp_test_YOUR_TEST_KEY_ID
RAZORPAY_KEY_SECRET=YOUR_TEST_KEY_SECRET
```

### Production (Live Mode)
```bash
RAZORPAY_KEY_ID=rzp_live_YOUR_LIVE_KEY_ID
RAZORPAY_KEY_SECRET=YOUR_LIVE_KEY_SECRET
```

## Getting Your Razorpay Keys

1. **Login to Razorpay Dashboard**: https://dashboard.razorpay.com
2. **Go to Settings > API Keys**
3. **Generate API Keys**:
   - For testing: Use "Test Mode" keys
   - For production: Use "Live Mode" keys

## Testing the Integration

### Test Card Details (for development)
- **Card Number**: 4111 1111 1111 1111
- **Expiry**: Any future date
- **CVV**: Any 3 digits
- **Name**: Any name

### Test UPI (for development)
- **UPI ID**: success@razorpay

## Payment Flow

1. **User clicks "Complete Purchase"** on checkout page
2. **Order is created** in your database
3. **Razorpay order is created** via API
4. **User is redirected** to payment page
5. **Razorpay modal opens** for payment
6. **Payment is processed** by Razorpay
7. **Callback is received** and verified
8. **Order is marked as paid** in your database

## Troubleshooting

### Common Issues

1. **"Invalid API Key" Error**
   - Check if environment variables are set correctly
   - Verify you're using the right keys (test vs live)

2. **"Order not found" Error**
   - Ensure Razorpay order is created before payment
   - Check if `razorpay_order_id` is saved in database

3. **"Signature verification failed" Error**
   - Verify your webhook secret is correct
   - Check if callback URL is accessible

4. **Payment not completing**
   - Check browser console for JavaScript errors
   - Verify Razorpay script is loading correctly

### Debug Mode

Enable debug logging by adding this to your `config/environments/development.rb`:

```ruby
config.log_level = :debug
```

## Security Notes

1. **Never commit API keys** to version control
2. **Use environment variables** for all sensitive data
3. **Always verify payment signatures** in production
4. **Use HTTPS** in production for all payment pages

## Support

- **Razorpay Documentation**: https://razorpay.com/docs/
- **Razorpay Support**: support@razorpay.com
- **Razorpay Status**: https://status.razorpay.com
