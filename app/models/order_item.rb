class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :validity_option, optional: true
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  
  scope :recent, -> { joins(:order).order('orders.created_at DESC') }
  
  def subtotal
    quantity * price
  end
  
  def unit_price
    price
  end
  
  def validity_display
    return validity_option&.display_duration if validity_option.present?
    return "Lifetime" if validity_type == 'lifetime'
    return "Standard" if validity_type.blank?
    "#{validity_duration} #{validity_type.capitalize}"
  end
end
