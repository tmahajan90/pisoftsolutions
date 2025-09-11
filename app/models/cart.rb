class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items
  
  def total_items
    cart_items.sum(:quantity)
  end
  
  def total_amount
    cart_items.includes(:product).sum do |item|
      price = item.validity_price || item.product.default_validity_option&.price || 0
      item.quantity * price
    end
  end
  
  def add_product(product, quantity = 1, validity_type = nil, validity_duration = nil, validity_price = nil)
    # Find existing cart item with the same product AND validity options
    cart_item = cart_items.find_by(
      product: product,
      validity_type: validity_type,
      validity_duration: validity_duration,
      validity_price: validity_price
    )
    
    if cart_item
      # If cart item exists with same validity options, increase quantity
      cart_item.quantity += quantity
      cart_item.save
    else
      # Create new cart item with the validity options
      cart_item = cart_items.create!(
        product: product,
        quantity: quantity,
        validity_type: validity_type,
        validity_duration: validity_duration,
        validity_price: validity_price
      )
    end
  end
  
  def remove_product(product, validity_type = nil, validity_duration = nil, validity_price = nil)
    cart_item = cart_items.find_by(
      product: product,
      validity_type: validity_type,
      validity_duration: validity_duration,
      validity_price: validity_price
    )
    cart_item&.destroy
  end
  
  def update_quantity(product, quantity, validity_type = nil, validity_duration = nil, validity_price = nil)
    cart_item = cart_items.find_by(
      product: product,
      validity_type: validity_type,
      validity_duration: validity_duration,
      validity_price: validity_price
    )
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
