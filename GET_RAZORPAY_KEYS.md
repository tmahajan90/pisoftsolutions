# 🔑 How to Get Your Razorpay API Keys

## Step 1: Create Razorpay Account

1. **Go to Razorpay**: https://razorpay.com
2. **Click "Sign Up"** or "Get Started"
3. **Fill in your details**:
   - Business name
   - Email address
   - Phone number
   - Business type
4. **Verify your email** and phone number

## Step 2: Get Your API Keys

1. **Login to Razorpay Dashboard**: https://dashboard.razorpay.com
2. **Go to Settings** (gear icon in top right)
3. **Click "API Keys"** in the left sidebar
4. **You'll see two sections**:
   - **Test Mode** (for development)
   - **Live Mode** (for production)

## Step 3: Generate Test API Keys

1. **In the "Test Mode" section**:
   - Click **"Generate Key Pair"**
   - This creates your test API keys
   - **Copy both the Key ID and Key Secret**

2. **Your keys will look like this**:
   ```
   Key ID: rzp_test_1234567890abcdef
   Key Secret: abcdef1234567890abcdef1234567890
   ```

## Step 4: Update Your .env File

1. **Open your .env file**:
   ```bash
   nano .env
   ```

2. **Replace the placeholder values** with your actual keys:
   ```bash
   # Razorpay Configuration
   # Replace these with your actual Razorpay API keys
   # Get your keys from: https://dashboard.razorpay.com/settings/api-keys

   RAZORPAY_KEY_ID=rzp_test_1234567890abcdef
   RAZORPAY_KEY_SECRET=abcdef1234567890abcdef1234567890

   # For production, use live keys:
   # RAZORPAY_KEY_ID=rzp_live_YOUR_LIVE_KEY_ID
   # RAZORPAY_KEY_SECRET=YOUR_LIVE_KEY_SECRET
   ```

3. **Save the file** (Ctrl+X, then Y, then Enter in nano)

## Step 5: Restart Your Rails Server

```bash
# Stop your current Rails server (Ctrl+C)
# Then restart it
rails server
```

## Step 6: Test the Configuration

```bash
# Test if the keys are working
ruby test_razorpay.rb
```

You should see:
```
✅ Environment variables found
✅ Razorpay connection successful!
✅ Test order created: order_xxxxx
✅ Amount: ₹1
```

## Step 7: Test the Payment Flow

1. **Add items to cart**
2. **Go to checkout**
3. **Click "Complete Purchase"**
4. **You should be redirected to payment page**
5. **Click "Pay" button**
6. **Razorpay modal should open**

## Test Payment Details

For testing, use these details:
- **Card Number**: 4111 1111 1111 1111
- **Expiry**: Any future date (e.g., 12/25)
- **CVV**: Any 3 digits (e.g., 123)
- **Name**: Any name
- **UPI ID**: success@razorpay

## Troubleshooting

### "Invalid API Key" Error
- Check if you copied the keys correctly
- Make sure you're using test keys for development
- Restart your Rails server after updating .env

### "Order not found" Error
- Verify Razorpay order creation in logs
- Check if the amount is valid (greater than 0)

### "Payment not completing"
- Check browser console for JavaScript errors
- Verify Razorpay script is loading

## Security Notes

⚠️ **Important**: 
- Never commit your `.env` file to version control
- Keep your API keys secure
- Use test keys for development
- Use live keys only in production

## Need Help?

- **Razorpay Support**: support@razorpay.com
- **Razorpay Documentation**: https://razorpay.com/docs/
- **Razorpay Status**: https://status.razorpay.com
