class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  
  def subtotal
    quantity * (validity_price || product.price)
  end
  
  def validity_display
    return "Lifetime" if validity_type == 'lifetime'
    return "Standard" if validity_type.blank?
    "#{validity_duration} #{validity_type.capitalize}"
  end
end
