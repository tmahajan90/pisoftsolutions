class Product < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :destroy
  has_many :validity_options, dependent: :destroy
  
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :in_stock, -> { where('stock > 0') }
  scope :by_category, ->(category) { where(category: category) }
  
  # Validity types
  VALIDITY_TYPES = ['days', 'months', 'years'].freeze
  
  # Accept nested attributes for validity options
  accepts_nested_attributes_for :validity_options, allow_destroy: true, reject_if: :all_blank
  
  # Serialize validity options (for backward compatibility during migration)
  serialize :validity_options, coder: JSON
  
  def discount_percentage
    return 0 if original_price.nil? || original_price <= price
    ((original_price - price) / original_price * 100).round
  end
  
  def in_stock?
    stock > 0
  end
  
  def validity_display
    return "Lifetime" if validity_type.blank? || validity_duration.blank?
    "#{validity_duration} #{validity_type.capitalize}"
  end
  
  def validity_price_display
    return price if validity_price.blank?
    validity_price
  end
  
  def has_validity_options?
    validity_type.present? && validity_duration.present?
  end
  

  
  def get_validity_options
    validity_options.ordered
  end
  
  def default_validity_option
    validity_options.default.first || validity_options.ordered.first
  end
end
