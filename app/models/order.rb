class Order < ApplicationRecord
  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_many :order_offers, dependent: :destroy
  has_many :offers, through: :order_offers
  
  validates :user_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending paid shipped delivered cancelled] }
  validates :payment_status, inclusion: { in: %w[pending success failed], allow_nil: true }
  validates :payment_gateway, inclusion: { in: %w[razorpay cashfree] }
  
  scope :recent, -> { order(created_at: :desc) }
  
  def self.statuses
    %w[pending paid shipped delivered cancelled]
  end
  
  def assign_user(user)
    update(user: user, user_email: user.email)
  end
  
  def subtotal
    order_items.sum(&:subtotal)
  end
  
  def total_discount
    order_offers.sum(:discount_amount)
  end
  
  def final_total
    subtotal - total_discount
  end
  
  def apply_offer(offer)
    return false unless offer.valid_for_amount?(subtotal)
    return false if order_offers.exists?(offer: offer)
    
    discount_amount = offer.calculate_discount(subtotal)
    order_offers.create!(
      offer: offer,
      discount_amount: discount_amount
    )
    
    update_total_amount
    true
  end
  
  def remove_offer(offer)
    order_offer = order_offers.find_by(offer: offer)
    return false unless order_offer
    
    order_offer.destroy
    update_total_amount
    true
  end
  
  def applied_offers
    offers.joins(:order_offers)
  end

  # Payment methods
  def create_payment_order(gateway = 'razorpay')
    payment_service = PaymentService.new(gateway)
    
    order_meta = {
      order_id: "order_#{id}",
      receipt: "receipt_#{id}_#{Time.current.to_i}",
      customer_id: user&.id,
      customer_name: user&.name || 'Customer',
      customer_email: user_email,
      customer_phone: user&.phone,
      return_url: build_payment_url("/payment/#{gateway}/callback/#{id}"),
      notify_url: build_payment_url("/payment/#{gateway}/webhook")
    }
    
    result = payment_service.create_order(total_amount, 'INR', order_meta)
    
    if result[:success]
      update(
        payment_gateway: gateway,
        payment_gateway_order_id: result[:payment_session_id] || result[:order_id]
      )
      result
    else
      result
    end
  end

  # Legacy method for backward compatibility
  def create_razorpay_order
    create_payment_order('razorpay')
  end

  def mark_payment_successful(payment_id, signature = nil)
    update(
      payment_gateway_payment_id: payment_id,
      payment_gateway_signature: signature,
      payment_status: 'success',
      status: 'paid'
    )
    
    # Send payment success email
    PaymentMailer.payment_success(self).deliver_now
  end

  # Legacy method for backward compatibility
  def razorpay_payment_id
    payment_gateway_payment_id
  end

  def razorpay_order_id
    payment_gateway_order_id
  end

  def mark_payment_failed
    update(payment_status: 'failed')
    
    # Send payment failed email
    PaymentMailer.payment_failed(self).deliver_now
  end

  def payment_successful?
    payment_status == 'success'
  end

  def payment_pending?
    payment_status == 'pending' || payment_status.nil?
  end

  def payment_failed?
    payment_status == 'failed'
  end

  def can_retry_payment?
    payment_pending? || payment_failed?
  end

  def payment_timeout?
    return false unless payment_pending?
    created_at < 15.minutes.ago
  end

  def payment_retry_count
    # This could be stored in a separate field if you want to track retry attempts
    # For now, we'll use a simple approach
    0
  end

  def send_payment_reminder
    return unless payment_pending?
    PaymentMailer.payment_reminder(self).deliver_now
  end

  def send_order_confirmation_email
    OrderMailer.order_confirmation(self).deliver_now
  rescue => e
    Rails.logger.error "Failed to send order confirmation email for order #{id}: #{e.message}"
  end

  def send_admin_order_notification
    OrderMailer.admin_order_notification(self).deliver_now
  rescue => e
    Rails.logger.error "Failed to send admin order notification for order #{id}: #{e.message}"
  end

  # Helper method to calculate item price from cart item
  def self.calculate_item_price(cart_item)
    if cart_item.validity_price.present? && cart_item.validity_price > 0
      cart_item.validity_price
    else
      # Find the matching validity option or use default
      validity_option = cart_item.product.validity_options.find do |option|
        option.duration_type == cart_item.validity_type && 
        option.duration_value == cart_item.validity_duration
      end
      
      validity_option&.price || cart_item.product.default_validity_option&.price || 0
    end
  end
  
  private
  
  def build_payment_url(path)
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
  
  def update_total_amount
    update(total_amount: final_total)
  end
end
