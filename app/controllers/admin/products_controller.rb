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
    # Process features parameter to handle array properly
    processed_params = product_params
    if processed_params[:features].present?
      # Filter out empty strings and ensure it's an array
      processed_params[:features] = processed_params[:features].reject(&:blank?)
    end
    
    @product = Product.new(processed_params)
    
    if @product.save
      # Create default trial option if no validity options were provided
      if @product.validity_options.empty?
        @product.validity_options.create!(
          duration_type: 'days',
          duration_value: 1,
          price: 1,
          label: '1 Day Trial',
          is_default: true,
          sort_order: 0
        )
      end
      
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
    # Ensure only one validity option is marked as default
    ensure_single_default_validity_option
    
    # Process features parameter to handle array properly
    processed_params = product_params
    if processed_params[:features].present?
      # Filter out empty strings and ensure it's an array
      processed_params[:features] = processed_params[:features].reject(&:blank?)
    end
    
    if @product.update(processed_params)
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
  
  def update_trial_prices
    new_price = params[:trial_price]&.to_f || 1.0
    
    # Update all trial options across all products
    trial_options = ValidityOption.where(duration_type: 'days', duration_value: 1)
    updated_count = trial_options.update_all(price: new_price)
    
    redirect_to admin_products_path, notice: "Updated trial price to ₹#{new_price} for #{updated_count} products."
  end
  
  def toggle_status
    @product = Product.find(params[:id])
    @product.update(active: !@product.active)
    
    status = @product.active? ? 'activated' : 'deactivated'
    redirect_to admin_products_path, notice: "Product '#{@product.name}' has been #{status}."
  end
  
  def bulk_toggle_status
    product_ids = params[:product_ids]
    new_status = params[:new_status] == 'true'
    
    if product_ids.present?
      Product.where(id: product_ids).update_all(active: new_status)
      status_text = new_status ? 'activated' : 'deactivated'
      redirect_to admin_products_path, notice: "#{product_ids.count} products have been #{status_text}."
    else
      redirect_to admin_products_path, alert: 'Please select products to update.'
    end
  end
  
  def toggle_validity_option
    validity_option = ValidityOption.find(params[:validity_option_id])
    validity_option.update(active: !validity_option.active)
    
    status = validity_option.active? ? 'activated' : 'deactivated'
    redirect_to admin_product_path(validity_option.product), notice: "Validity option '#{validity_option.label}' has been #{status}."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :description, :price, :original_price, :category, 
                                   :image_url, :color, :badge, :rating, :stock, :active, :validity_type, 
                                   :validity_duration, :validity_price, :validity_options, features: [],
                                   validity_options_attributes: [:id, :duration_type, :duration_value, 
                                                               :price, :label, :is_default, :sort_order, :active, :_destroy])
  end
  
  def ensure_single_default_validity_option
    # Get the validity options parameters
    validity_options_params = params.dig(:product, :validity_options_attributes)
    return unless validity_options_params
    
    # Find which option is being marked as default
    default_option_id = nil
    validity_options_params.each do |index, option_params|
      if option_params[:is_default] == '1' || option_params[:is_default] == true
        default_option_id = option_params[:id]
        break
      end
    end
    
    # If a default option is being set, unset all others
    if default_option_id
      @product.validity_options.where.not(id: default_option_id).update_all(is_default: false)
    end
  end
end
