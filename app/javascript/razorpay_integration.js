// Razorpay Integration JavaScript
// Handles payment processing with better error handling and UX

class RazorpayIntegration {
  constructor(options = {}) {
    this.options = {
      key: options.key,
      amount: options.amount,
      currency: options.currency || 'INR',
      name: options.name || 'Pisoft Solutions',
      description: options.description,
      orderId: options.orderId,
      callbackUrl: options.callbackUrl,
      prefill: options.prefill || {},
      theme: options.theme || { color: '#6366F1' }
    };
    
    this.button = null;
    this.isProcessing = false;
  }

  // Initialize the payment button
  init(buttonSelector) {
    this.button = document.querySelector(buttonSelector);
    if (!this.button) {
      console.error('Payment button not found');
      return;
    }

    this.button.addEventListener('click', (e) => this.handlePaymentClick(e));
  }

  // Handle payment button click
  handlePaymentClick(e) {
    e.preventDefault();
    
    if (this.isProcessing) {
      return; // Prevent double clicks
    }

    this.isProcessing = true;
    this.updateButtonState('Processing...', true);

    try {
      this.openPaymentModal();
    } catch (error) {
      console.error('Error opening payment modal:', error);
      this.showMessage('Payment initialization failed. Please try again.', 'error');
      this.resetButtonState();
    }
  }

  // Open Razorpay payment modal
  openPaymentModal() {
    const options = {
      key: this.options.key,
      amount: this.options.amount,
      currency: this.options.currency,
      name: this.options.name,
      description: this.options.description,
      order_id: this.options.orderId,
      handler: (response) => this.handlePaymentSuccess(response),
      prefill: this.options.prefill,
      theme: this.options.theme,
      modal: {
        ondismiss: () => this.handleModalDismiss()
      }
    };

    const rzp = new Razorpay(options);
    
    // Handle payment failures
    rzp.on('payment.failed', (response) => {
      this.handlePaymentFailure(response);
    });

    rzp.open();
  }

  // Handle successful payment
  handlePaymentSuccess(response) {
    this.showMessage('Payment successful! Redirecting...', 'success');
    
    // Create form to submit payment details
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = this.options.callbackUrl;
    
    const fields = {
      'razorpay_payment_id': response.razorpay_payment_id,
      'razorpay_order_id': response.razorpay_order_id,
      'razorpay_signature': response.razorpay_signature,
      'authenticity_token': this.getAuthenticityToken()
    };
    
    Object.keys(fields).forEach(key => {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = key;
      input.value = fields[key];
      form.appendChild(input);
    });
    
    document.body.appendChild(form);
    form.submit();
  }

  // Handle payment failure
  handlePaymentFailure(response) {
    console.error('Payment failed:', response);
    this.showMessage(`Payment failed: ${response.error.description}`, 'error');
    this.resetButtonState();
  }

  // Handle modal dismissal
  handleModalDismiss() {
    this.resetButtonState();
  }

  // Update button state
  updateButtonState(text, disabled = false) {
    if (this.button) {
      this.button.disabled = disabled;
      this.button.innerHTML = `<i class="fas fa-spinner fa-spin mr-2"></i>${text}`;
    }
  }

  // Reset button to original state
  resetButtonState() {
    this.isProcessing = false;
    if (this.button) {
      this.button.disabled = false;
      this.button.innerHTML = '<i class="fas fa-lock mr-2"></i>Pay Now';
    }
  }

  // Show message to user
  showMessage(message, type = 'info') {
    const messageDiv = document.createElement('div');
    messageDiv.className = 'fixed top-4 right-4 z-50 p-4 rounded-lg shadow-lg max-w-sm';
    
    switch (type) {
      case 'success':
        messageDiv.className += ' bg-green-500 text-white';
        break;
      case 'error':
        messageDiv.className += ' bg-red-500 text-white';
        break;
      default:
        messageDiv.className += ' bg-blue-500 text-white';
    }
    
    messageDiv.innerHTML = message;
    document.body.appendChild(messageDiv);
    
    // Remove message after 5 seconds
    setTimeout(() => {
      if (messageDiv.parentNode) {
        messageDiv.parentNode.removeChild(messageDiv);
      }
    }, 5000);
  }

  // Get CSRF token
  getAuthenticityToken() {
    const token = document.querySelector('meta[name="csrf-token"]');
    return token ? token.getAttribute('content') : '';
  }

  // Validate configuration
  validateConfig() {
    const required = ['key', 'amount', 'orderId', 'callbackUrl'];
    const missing = required.filter(field => !this.options[field]);
    
    if (missing.length > 0) {
      console.error('Missing required configuration:', missing);
      return false;
    }
    
    return true;
  }
}

// Export for use in other files
window.RazorpayIntegration = RazorpayIntegration;
