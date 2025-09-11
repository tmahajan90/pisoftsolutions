class UserFeature < ApplicationRecord
  belongs_to :user
  belongs_to :feature
  belongs_to :subscription, optional: true
  
  validates :status, presence: true, inclusion: { in: %w[active trial expired suspended inactive] }
  validates :user_id, uniqueness: { scope: :feature_id }
  
  enum status: { 
    active: 0, 
    trial: 1, 
    expired: 2, 
    suspended: 3, 
    inactive: 4 
  }
  
  scope :active, -> { where(status: :active) }
  scope :trial, -> { where(status: :trial) }
  scope :expired, -> { where(status: :expired) }
  scope :suspended, -> { where(status: :suspended) }
  scope :expiring_soon, -> { where('expires_at <= ? AND expires_at > ?', 7.days.from_now, Time.current) }
  scope :expired_recently, -> { where('expires_at <= ? AND expires_at > ?', Time.current, 30.days.ago) }
  
  before_save :set_default_expiry_if_needed
  after_update :handle_status_change
  
  def active?
    status == 'active' && (expires_at.nil? || expires_at > Time.current)
  end
  
  def trial?
    status == 'trial' && (trial_ends_at.nil? || trial_ends_at > Time.current)
  end
  
  def expired?
    status == 'expired' || (expires_at.present? && expires_at <= Time.current)
  end
  
  def suspended?
    status == 'suspended'
  end
  
  def can_access?
    return false if suspended?
    return false if expired?
    return true if active?
    return true if trial?
    false
  end
  
  def days_remaining
    return nil unless expires_at
    return 0 if expired?
    
    ((expires_at - Time.current) / 1.day).ceil
  end
  
  def trial_days_remaining
    return nil unless trial_ends_at
    return 0 if trial_ends_at <= Time.current
    
    ((trial_ends_at - Time.current) / 1.day).ceil
  end
  
  def status_display
    case status
    when 'active'
      if expires_at.present?
        "Active (#{days_remaining} days left)"
      else
        'Active'
      end
    when 'trial'
      if trial_ends_at.present?
        "Trial (#{trial_days_remaining} days left)"
      else
        'Trial'
      end
    when 'expired'
      'Expired'
    when 'suspended'
      'Suspended'
    when 'inactive'
      'Inactive'
    else
      status.humanize
    end
  end
  
  def auto_renew?
    subscription&.auto_renew? || false
  end
  
  def billing_cycle
    subscription&.billing_cycle
  end
  
  def next_billing_date
    subscription&.next_billing_date
  end
  
  def price
    subscription&.price || 0
  end
  
  def plan_name
    subscription&.plan_name
  end
  
  def upgrade_available?
    return false unless feature.available_pricing_tiers.count > 1
    
    current_tier = subscription&.plan_name
    return true unless current_tier
    
    current_tier_index = feature.available_pricing_tiers.find_index { |tier| tier['name'] == current_tier }
    current_tier_index && current_tier_index < feature.available_pricing_tiers.count - 1
  end
  
  def downgrade_available?
    return false unless feature.available_pricing_tiers.count > 1
    
    current_tier = subscription&.plan_name
    return false unless current_tier
    
    current_tier_index = feature.available_pricing_tiers.find_index { |tier| tier['name'] == current_tier }
    current_tier_index && current_tier_index > 0
  end
  
  def next_tier
    return nil unless upgrade_available?
    
    current_tier = subscription&.plan_name
    current_tier_index = feature.available_pricing_tiers.find_index { |tier| tier['name'] == current_tier }
    feature.available_pricing_tiers[current_tier_index + 1]
  end
  
  def previous_tier
    return nil unless downgrade_available?
    
    current_tier = subscription&.plan_name
    current_tier_index = feature.available_pricing_tiers.find_index { |tier| tier['name'] == current_tier }
    feature.available_pricing_tiers[current_tier_index - 1]
  end
  
  def usage_stats
    {
      total_usage: calculate_total_usage,
      usage_limit: subscription&.usage_limit,
      usage_percentage: calculate_usage_percentage
    }
  end
  
  def within_usage_limits?
    return true unless subscription&.usage_limit
    
    current_usage = calculate_total_usage
    current_usage <= subscription.usage_limit
  end
  
  def usage_warning_threshold_reached?
    return false unless subscription&.usage_limit
    
    current_usage = calculate_total_usage
    threshold = subscription.usage_limit * 0.8 # 80% threshold
    current_usage >= threshold
  end
  
  def usage_critical_threshold_reached?
    return false unless subscription&.usage_limit
    
    current_usage = calculate_total_usage
    threshold = subscription.usage_limit * 0.95 # 95% threshold
    current_usage >= threshold
  end
  
  def extend_access(days)
    new_expiry = (expires_at || Time.current) + days.days
    update!(expires_at: new_expiry)
  end
  
  def suspend_access(reason = nil)
    update!(
      status: :suspended,
      suspended_at: Time.current,
      suspension_reason: reason
    )
  end
  
  def reactivate_access
    return false unless suspended?
    
    update!(
      status: :active,
      suspended_at: nil,
      suspension_reason: nil
    )
  end
  
  def expire_access
    update!(
      status: :expired,
      expires_at: Time.current
    )
  end
  
  def start_trial(trial_days = nil)
    trial_duration = trial_days || feature.trial_days
    return false unless trial_duration && trial_duration > 0
    
    update!(
      status: :trial,
      trial_used: true,
      trial_started_at: Time.current,
      trial_ends_at: trial_duration.days.from_now,
      expires_at: trial_duration.days.from_now
    )
  end
  
  def convert_trial_to_subscription(subscription_plan)
    return false unless trial?
    
    # Create subscription
    new_subscription = feature.subscriptions.create!(
      user: user,
      plan_name: subscription_plan['name'],
      price: subscription_plan['price'],
      billing_cycle: subscription_plan['billing_cycle'] || 'monthly',
      status: :active,
      started_at: Time.current
    )
    
    # Update user feature
    update!(
      status: :active,
      subscription: new_subscription,
      expires_at: calculate_subscription_expiry(subscription_plan['billing_cycle'])
    )
    
    new_subscription
  end
  
  private
  
  def set_default_expiry_if_needed
    if active? && expires_at.nil?
      self.expires_at = 1.month.from_now
    end
  end
  
  def handle_status_change
    # Handle status-specific logic
    case status
    when 'expired'
      handle_expiration
    when 'suspended'
      handle_suspension
    when 'active'
      handle_reactivation
    end
  end
  
  def handle_expiration
    # Send expiration notification
    # UserMailer.feature_expired(user, feature).deliver_later
  end
  
  def handle_suspension
    # Send suspension notification
    # UserMailer.feature_suspended(user, feature, suspension_reason).deliver_later
  end
  
  def handle_reactivation
    # Send reactivation notification
    # UserMailer.feature_reactivated(user, feature).deliver_later
  end
  
  def calculate_total_usage
    # This would be implemented based on specific feature usage tracking
    # For now, return 0 as placeholder
    0
  end
  
  def calculate_usage_percentage
    return 0 unless subscription&.usage_limit
    
    current_usage = calculate_total_usage
    (current_usage.to_f / subscription.usage_limit * 100).round(2)
  end
  
  def calculate_subscription_expiry(billing_cycle)
    case billing_cycle
    when 'daily'
      1.day.from_now
    when 'weekly'
      1.week.from_now
    when 'monthly'
      1.month.from_now
    when 'quarterly'
      3.months.from_now
    when 'yearly'
      1.year.from_now
    else
      1.month.from_now
    end
  end
end
