class ValidityOption < ApplicationRecord
  belongs_to :product
  has_many :order_items, dependent: :nullify
  
  validates :duration_type, presence: true, inclusion: { in: %w[days months years lifetime] }
  validates :duration_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :label, presence: true
  validate :only_one_default_per_product, if: :is_default?
  
  scope :ordered, -> { order(:sort_order, :duration_value) }
  scope :sorted_by_duration, -> { 
    order(
      Arel.sql("CASE duration_type 
        WHEN 'days' THEN 1 
        WHEN 'months' THEN 2 
        WHEN 'years' THEN 3 
        WHEN 'lifetime' THEN 4 
        ELSE 5 END"),
      :duration_value
    ) 
  }
  scope :default, -> { where(is_default: true) }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  
  def display_duration
    return "Lifetime" if duration_type == 'lifetime'
    "#{duration_value} #{duration_type.capitalize}"
  end
  
  def lifetime?
    duration_type == 'lifetime'
  end
  
  def trial?
    duration_type == 'days' && duration_value == 1
  end
  
  def active?
    active
  end
  
  def inactive?
    !active
  end
  
  def display_duration
    return "Lifetime" if duration_type == 'lifetime'
    return "1 Day Trial" if trial?
    "#{duration_value} #{duration_type.capitalize}"
  end
  
  private
  
  def only_one_default_per_product
    # Check if there's already another default option for this product
    existing_default = product.validity_options.where(is_default: true)
    existing_default = existing_default.where.not(id: id) if persisted?
    
    if existing_default.exists?
      errors.add(:is_default, "only one validity option can be set as default per product")
    end
  end
end
