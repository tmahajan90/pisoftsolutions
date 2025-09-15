require 'bcrypt'

class User < ApplicationRecord
  has_secure_password
  
  has_many :orders, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :trial_usages, dependent: :destroy
  
  # New feature-based relationships
  has_many :user_features, dependent: :destroy
  has_many :features, through: :user_features
  has_many :subscriptions, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :phone, presence: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }
  
  # Email callbacks
  after_create :send_welcome_email
  after_create :send_admin_signup_notification
  
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
  
  # Feature access methods
  def has_feature_access?(feature)
    return true if admin?
    return false unless feature
    
    user_features.exists?(feature: feature, status: [:active, :trial])
  end
  
  def can_access_feature?(feature)
    return true if admin?
    return false unless feature
    
    user_feature = user_features.find_by(feature: feature)
    return false unless user_feature
    
    user_feature.can_access?
  end
  
  def active_features
    features.joins(:user_features)
            .where(user_features: { status: :active })
            .where('user_features.expires_at IS NULL OR user_features.expires_at > ?', Time.current)
  end
  
  def trial_features
    features.joins(:user_features)
            .where(user_features: { status: :trial })
            .where('user_features.trial_ends_at IS NULL OR user_features.trial_ends_at > ?', Time.current)
  end
  
  def expired_features
    features.joins(:user_features)
            .where(user_features: { status: :expired })
            .or(features.joins(:user_features)
                        .where('user_features.expires_at <= ?', Time.current))
  end
  
  def suspended_features
    features.joins(:user_features)
            .where(user_features: { status: :suspended })
  end
  
  def available_features
    Feature.active.where.not(id: features.pluck(:id))
  end
  
  def features_with_trial_available
    available_features.select { |feature| feature.can_user_trial?(self) }
  end
  
  def start_trial_for_feature(feature)
    return false unless feature.can_user_trial?(self)
    
    feature.start_trial_for_user(self)
  end
  
  def subscribe_to_feature(feature, plan_name)
    return false unless feature
    
    plan = feature.pricing_tier_by_name(plan_name)
    return false unless plan
    
    # Create subscription
    subscription = feature.subscriptions.create!(
      user: self,
      plan_name: plan['name'],
      price: plan['price'],
      billing_cycle: plan['billing_cycle'] || 'monthly',
      status: :active,
      started_at: Time.current,
      usage_limit: plan['usage_limit'],
      features: plan['features']
    )
    
    # Create or update user feature
    user_feature = user_features.find_or_initialize_by(feature: feature)
    user_feature.assign_attributes(
      status: :active,
      subscription: subscription,
      expires_at: subscription.next_billing_date
    )
    user_feature.save!
    
    subscription
  end
  
  def cancel_feature_subscription(feature, reason = nil)
    subscription = subscriptions.joins(:user_features)
                               .where(feature: feature, user_features: { status: :active })
                               .first
    return false unless subscription
    
    subscription.cancel_subscription(reason)
  end
  
  def suspend_feature_access(feature, reason = nil)
    user_feature = user_features.find_by(feature: feature)
    return false unless user_feature
    
    user_feature.suspend_access(reason)
  end
  
  def reactivate_feature_access(feature)
    user_feature = user_features.find_by(feature: feature, status: :suspended)
    return false unless user_feature
    
    user_feature.reactivate_access
  end
  
  def feature_subscription(feature)
    subscriptions.joins(:user_features)
                .where(feature: feature, user_features: { status: :active })
                .first
  end
  
  def feature_status(feature)
    user_feature = user_features.find_by(feature: feature)
    return 'not_purchased' unless user_feature
    
    user_feature.status
  end
  
  def total_monthly_revenue
    subscriptions.active.sum { |sub| sub.monthly_price }
  end
  
  def total_yearly_revenue
    subscriptions.active.sum { |sub| sub.yearly_price }
  end
  
  def features_by_category
    active_features.group_by(&:category)
  end
  
  def usage_summary
    {
      total_features: active_features.count,
      trial_features: trial_features.count,
      expired_features: expired_features.count,
      suspended_features: suspended_features.count,
      monthly_revenue: total_monthly_revenue,
      yearly_revenue: total_yearly_revenue
    }
  end

  private

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_now
  rescue => e
    Rails.logger.error "Failed to send welcome email to #{email}: #{e.message}"
  end

  def send_admin_signup_notification
    UserMailer.admin_signup_notification(self).deliver_now
  rescue => e
    Rails.logger.error "Failed to send admin signup notification for #{email}: #{e.message}"
  end
end

