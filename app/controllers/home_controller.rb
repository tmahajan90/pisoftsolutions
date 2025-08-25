class HomeController < ApplicationController
  before_action :get_or_create_cart

  def index
    @featured_products = Product.active.limit(3)
  end

  def products
    @products = Product.active
    @categories = Product.active.distinct.pluck(:category)
  end

  def product_detail
    @product = Product.active.find(params[:id])
    @related_products = Product.active.where(category: @product.category).where.not(id: @product.id).limit(4)
  end

  def validity_options
    @product = Product.find(params[:id])
    render json: @product.get_validity_options
  end

  def pricing
  end

  def contact
  end

  def about
  end

  def features
  end

  def submit_contact
    @contact = Contact.new(contact_params)
    
    if @contact.save
      # In a real application, you would also send email notification here
      # ContactMailer.new_contact(@contact).deliver_now
      
      redirect_to contact_path, notice: 'Thank you for your message! We will get back to you within 24 hours.'
    else
      # Store errors in flash and redirect back to contact form
      flash[:alert] = "Please correct the following errors: #{@contact.errors.full_messages.join(', ')}"
      redirect_to contact_path
    end
  end

  private

  def get_or_create_cart
    session_id = session.id.to_s
    @cart = Cart.find_or_create_by(session_id: session_id)
  end

  def contact_params
    params.permit(:name, :phone, :email, :source, :role, :requirement, :message)
  end
end
