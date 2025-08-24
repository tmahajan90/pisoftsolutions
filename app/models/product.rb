class Product < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :destroy
  
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :in_stock, -> { where('stock > 0') }
  scope :by_category, ->(category) { where(category: category) }
  
  # Validity types
  VALIDITY_TYPES = ['days', 'months', 'years'].freeze
  
  # Serialize validity options
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
  
  def default_validity_options
    [
      { duration: 30, type: 'days', price: (price * 0.3).round, label: '30 Days' },
      { duration: 90, type: 'days', price: (price * 0.6).round, label: '3 Months' },
      { duration: 180, type: 'days', price: (price * 0.8).round, label: '6 Months' },
      { duration: 365, type: 'days', price: price, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: (price * 1.5).round, label: 'Lifetime' }
    ]
  end
  
  def get_validity_options
    return default_validity_options if validity_options.blank?
    validity_options
  end
end
