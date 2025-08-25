class TrialUsage < ApplicationRecord
  belongs_to :user
  belongs_to :product
  
  validates :user_id, uniqueness: { scope: :product_id, message: "has already used trial for this product" }
  validates :used_at, presence: true
  
  scope :recent, -> { order(used_at: :desc) }
  
  def self.mark_as_used(user, product)
    find_or_create_by(user: user, product: product) do |trial_usage|
      trial_usage.used_at = Time.current
    end
  end
  
  def self.has_used_trial?(user, product)
    exists?(user: user, product: product)
  end
  
  def self.reset_for_user(user, product)
    where(user: user, product: product).destroy_all
  end
end
