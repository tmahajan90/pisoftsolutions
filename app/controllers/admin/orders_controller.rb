class Admin::OrdersController < AdminController
  before_action :set_order, only: [:show, :edit, :update, :destroy]

  def index
    @orders = Order.includes(:user, :order_items, :products)
                   .order(created_at: :desc)
                   .page(params[:page])
                   .per(20)
    
    if params[:status].present?
      @orders = @orders.where(status: params[:status])
    end
    
    if params[:search].present?
      @orders = @orders.joins(:user).where("users.name ILIKE ? OR users.email ILIKE ? OR orders.id::text ILIKE ?", 
                                          "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    @total_revenue = @orders.where(status: ['paid', 'shipped', 'delivered']).sum(:total_amount)
    @pending_orders = @orders.where(status: 'pending').count
  end

  def show
    @order_items = @order.order_items.includes(:product)
    @applied_offers = @order.applied_offers
  end

  def edit
  end

  def update
    if @order.update(order_params)
      redirect_to admin_order_path(@order), notice: 'Order updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy
    redirect_to admin_orders_path, notice: 'Order deleted successfully.'
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:status, :payment_status, :user_email)
  end
end
