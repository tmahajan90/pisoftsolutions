class Admin::ProductsController < AdminController
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  def index
    # Base query for filtering
    base_query = Product.order(created_at: :desc)
    
    if params[:search].present?
      base_query = base_query.where("name ILIKE ? OR description ILIKE ? OR category ILIKE ?", 
                                   "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    if params[:category].present?
      base_query = base_query.where(category: params[:category])
    end
    
    # Get paginated products for display (increased limit for better testing)
    @products = base_query.limit(50)
    
    # Calculate statistics on the full filtered dataset (not limited)
    @categories = Product.distinct.pluck(:category)
    @total_products = base_query.count
    @low_stock_products = base_query.where('stock < ?', 10).count
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    
    if @product.save
      redirect_to admin_product_path(@product), notice: 'Product created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @order_items = @product.order_items.includes(:order).recent.limit(10)
    @total_sold = @product.order_items.sum(:quantity)
    @total_revenue = @product.order_items.joins(:order)
                            .where(orders: { status: ['paid', 'shipped', 'delivered'] })
                            .sum('order_items.price * order_items.quantity')
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to admin_product_path(@product), notice: 'Product updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.order_items.exists?
      redirect_to admin_products_path, alert: 'Cannot delete product with existing orders.'
    else
      @product.destroy
      redirect_to admin_products_path, notice: 'Product deleted successfully.'
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :description, :price, :original_price, :category, 
                                   :image_url, :color, :badge, :rating, :stock, :validity_type, 
                                   :validity_duration, :validity_price, :validity_options,
                                   validity_options_attributes: [:id, :duration_type, :duration_value, 
                                                               :price, :label, :is_default, :sort_order, :_destroy])
  end
end
