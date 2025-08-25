class CartsController < ApplicationController
  before_action :get_or_create_cart
  
  def show
    @cart_items = @cart.cart_items.includes(:product)
  end
  
  def add_item
    product = Product.find(params[:product_id])
    quantity = params[:quantity]&.to_i || 1
    validity_type = params[:validity]
    validity_duration = params[:duration]&.to_i
    validity_price = params[:price]&.to_f
    is_trial = params[:is_trial] == true || params[:is_trial] == 'true'
    
    # Check if this is a trial and if user has already used it
    if is_trial && current_user
      if current_user.has_used_trial_for?(product)
        render json: { success: false, message: "You have already used the trial for this product!" }
        return
      end
    end
    
    if product.in_stock?
      @cart.add_product(product, quantity, validity_type, validity_duration, validity_price)
      
      # Mark trial as used if this is a trial and user is logged in
      trial_marked = false
      if is_trial && current_user
        current_user.mark_trial_as_used(product)
        trial_marked = true
      end
      
      render json: { 
        success: true, 
        message: "#{product.name} added to cart!",
        cart_count: @cart.total_items,
        cart_total: @cart.total_amount,
        trial_marked: trial_marked
      }
    else
      render json: { success: false, message: "Product is out of stock!" }
    end
  end
  
  def remove_item
    product = Product.find(params[:product_id])
    @cart.remove_product(product)
    
    render json: { 
      success: true, 
      message: "#{product.name} removed from cart!",
      cart_count: @cart.total_items,
      cart_total: @cart.total_amount
    }
  end
  
  def update_quantity
    product = Product.find(params[:product_id])
    quantity = params[:quantity]&.to_i || 0
    
    @cart.update_quantity(product, quantity)
    
    render json: { 
      success: true, 
      cart_count: @cart.total_items,
      cart_total: @cart.total_amount
    }
  end
  
  def clear
    @cart.clear
    render json: { success: true, message: "Cart cleared!" }
  end
  
  private
  
  def get_or_create_cart
    session_id = session.id.to_s
    @cart = Cart.find_or_create_by(session_id: session_id)
  end
end
