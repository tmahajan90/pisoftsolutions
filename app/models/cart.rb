class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items
  
  def total_items
    cart_items.sum(:quantity)
  end
  
  def total_amount
    cart_items.includes(:product).sum do |item|
      price = item.validity_price || item.product.price
      item.quantity * price
    end
  end
  
  def add_product(product, quantity = 1, validity_type = nil, validity_duration = nil, validity_price = nil)
    cart_item = cart_items.find_or_initialize_by(product: product)
    cart_item.quantity = (cart_item.quantity || 0) + quantity
    
    # Update validity information if provided
    if validity_type.present?
      cart_item.validity_type = validity_type
      cart_item.validity_duration = validity_duration
      cart_item.validity_price = validity_price
    end
    
    cart_item.save
  end
  
  def remove_product(product)
    cart_items.find_by(product: product)&.destroy
  end
  
  def update_quantity(product, quantity)
    cart_item = cart_items.find_by(product: product)
    if cart_item
      if quantity <= 0
        cart_item.destroy
      else
        cart_item.update(quantity: quantity)
      end
    end
  end
  
  def clear
    cart_items.destroy_all
  end
end
