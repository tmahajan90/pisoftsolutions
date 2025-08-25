class Admin::OrdersController < AdminController
  before_action :set_order, only: [:show, :edit, :update, :destroy]

  def index
    # Base query for filtering
    base_query = Order.includes(:user, :order_items, :products)
    
    if params[:status].present?
      base_query = base_query.where(status: params[:status])
    end
    
    if params[:user_id].present?
      base_query = base_query.where(user_id: params[:user_id])
    end
    
    if params[:search].present?
      base_query = base_query.joins(:user).where("users.name ILIKE ? OR users.email ILIKE ? OR orders.id::text ILIKE ?", 
                                          "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    # Get paginated orders for display
    @orders = base_query.order(created_at: :desc).limit(20)
    
    # Calculate statistics on the full filtered dataset (not limited)
    @total_revenue = base_query.where(status: ['paid', 'shipped', 'delivered']).sum(:total_amount)
    @pending_orders = base_query.where(status: 'pending').count
    @total_orders = base_query.count
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
