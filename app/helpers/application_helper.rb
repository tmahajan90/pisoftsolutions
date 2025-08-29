module ApplicationHelper
  # Helper method to safely display product icons with fallback
  def product_icon(product, fallback_icon = 'fas fa-box')
    if product.image_url.present?
      product.image_url.strip
    else
      fallback_icon
    end
  end
end
