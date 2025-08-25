class ValidityOption < ApplicationRecord
  belongs_to :product
  has_many :order_items, dependent: :nullify
  
  validates :duration_type, presence: true, inclusion: { in: %w[days months years lifetime] }
  validates :duration_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :label, presence: true
  
  scope :ordered, -> { order(:sort_order, :duration_value) }
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
end
