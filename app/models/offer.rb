class Offer < ApplicationRecord
  has_many :order_offers, dependent: :destroy
  has_many :orders, through: :order_offers
  
  validates :name, presence: true
  validates :discount_type, presence: true, inclusion: { in: %w[percentage fixed] }
  validates :discount_value, presence: true, numericality: { greater_than: 0 }
  validates :code, presence: true, uniqueness: true, format: { with: /\A[A-Z0-9]+\z/ }
  validates :valid_from, presence: true
  validates :valid_until, presence: true
  validates :usage_limit, numericality: { greater_than: 0 }, allow_nil: true
  
  scope :active, -> { where(active: true) }
  scope :current, -> { where('valid_from <= ? AND valid_until >= ?', Time.current, Time.current) }
  scope :available, -> { active.current }
  
  def self.discount_types
    %w[percentage fixed]
  end
  
  def valid_for_amount?(amount)
    return false unless active?
    return false unless current?
    return false if usage_limit_reached?
    amount >= minimum_amount
  end
  
  def current?
    Time.current.between?(valid_from, valid_until)
  end
  
  def usage_limit_reached?
    return false if usage_limit.nil?
    order_offers.count >= usage_limit
  end
  
  def calculate_discount(subtotal)
    case discount_type
    when 'percentage'
      (subtotal * discount_value / 100.0).round(2)
    when 'fixed'
      [discount_value, subtotal].min
    else
      0
    end
  end
  
  def display_discount
    case discount_type
    when 'percentage'
      "#{discount_value}% OFF"
    when 'fixed'
      "$#{discount_value} OFF"
    end
  end
end
