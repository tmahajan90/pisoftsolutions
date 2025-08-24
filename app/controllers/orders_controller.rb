class OrdersController < ApplicationController
  before_action :require_login
  before_action :get_or_create_cart, only: [:new, :create]
  before_action :set_order, only: [:show]
  
  def index
    @orders = current_user.orders.includes(:order_items, :products, :offers).recent
  end
  
  def new
    @cart_items = @cart.cart_items.includes(:product)
    @order = Order.new
  end
  
  def create
    @order = Order.new(order_params)
    @order.user = current_user
    @order.user_email = current_user.email
    @order.total_amount = @cart.total_amount
    @order.status = 'pending'
    
    if @order.save
      # Create order items from cart
      @cart.cart_items.each do |cart_item|
        OrderItem.create!(
          order: @order,
          product: cart_item.product,
          quantity: cart_item.quantity,
          price: cart_item.validity_price || cart_item.product.price,
          validity_type: cart_item.validity_type,
          validity_duration: cart_item.validity_duration
        )
      end
      
      # Clear the cart
      @cart.clear
      
      redirect_to @order, notice: 'Order placed successfully!'
    else
      @cart_items = @cart.cart_items.includes(:product)
      render :new
    end
  end
  
  def show
    @order_items = @order.order_items.includes(:product)
    @applied_offers = @order.applied_offers
  end
  
  private
  
  def set_order
    @order = current_user.orders.find(params[:id])
  end
  
  def order_params
    params.require(:order).permit(:user_email)
  end
  
  def get_or_create_cart
    session_id = session.id.to_s
    @cart = Cart.find_or_create_by(session_id: session_id)
    
    # If user is logged in, associate the cart with them
    if current_user && @cart.user_id.nil?
      @cart.update(user_id: current_user.id)
    end
  end
end
