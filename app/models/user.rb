require 'bcrypt'

class User < ApplicationRecord
  has_secure_password
  
  has_many :orders, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :trial_usages, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :phone, presence: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }
  
  # Admin role functionality
  enum role: { user: 0, admin: 1 }
  
  scope :recent, -> { order(created_at: :desc) }
  scope :admins, -> { where(role: :admin) }
  scope :users, -> { where(role: :user) }
  
  def admin?
    role == 'admin'
  end
  
  def self.find_or_create_by_email(email, attributes = {})
    user = find_by(email: email)
    if user
      user.update(attributes) if attributes.any?
      user
    else
      create(attributes.merge(email: email))
    end
  end
  
  def display_name
    name.present? ? name : email
  end
  
  def total_orders
    orders.count
  end
  
  def total_spent
    orders.where(status: ['paid', 'shipped', 'delivered']).sum(:total_amount)
  end
  
  def last_order_date
    orders.recent.first&.created_at
  end
  
  # Trial-related methods
  def has_used_trial_for?(product)
    TrialUsage.has_used_trial?(self, product)
  end
  
  def can_use_trial_for?(product)
    !has_used_trial_for?(product)
  end
  
  def mark_trial_as_used(product)
    TrialUsage.mark_as_used(self, product)
  end
  
  def reset_trial_for(product)
    TrialUsage.reset_for_user(self, product)
  end
  
  def trial_usage_count
    trial_usages.count
  end
  
  def recent_trial_usages(limit = 5)
    trial_usages.recent.limit(limit)
  end
end

