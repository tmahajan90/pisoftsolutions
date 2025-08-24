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
  def create_razorpay_order
    razorpay_service = RazorpayService.new
    result = razorpay_service.create_order(final_total, 'INR', "order_#{id}")
    
    if result[:success]
      update(razorpay_order_id: result[:order_id])
      result
    else
      result
    end
  end

  def mark_payment_successful(payment_id)
    update(
      razorpay_payment_id: payment_id,
      payment_status: 'success',
      status: 'paid'
    )
  end

  def mark_payment_failed
    update(payment_status: 'failed')
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
  
  private
  
  def update_total_amount
    update(total_amount: final_total)
  end
end
