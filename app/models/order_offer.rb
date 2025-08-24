class OrderOffer < ApplicationRecord
  belongs_to :order
  belongs_to :offer
  
  validates :discount_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :applied_at, presence: true
  
  before_validation :set_applied_at, on: :create
  
  private
  
  def set_applied_at
    self.applied_at = Time.current if applied_at.nil?
  end
end
