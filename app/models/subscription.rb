class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :feature
  has_many :user_features, dependent: :destroy
  has_many :orders, as: :orderable, dependent: :destroy
  
  validates :plan_name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :billing_cycle, presence: true, inclusion: { in: %w[daily weekly monthly quarterly yearly] }
  validates :status, presence: true, inclusion: { in: %w[active inactive cancelled suspended] }
  
  enum status: { 
    active: 0, 
    inactive: 1, 
    cancelled: 2, 
    suspended: 3 
  }
  
  enum billing_cycle: { 
    daily: 0, 
    weekly: 1, 
    monthly: 2, 
    quarterly: 3, 
    yearly: 4 
  }
  
  scope :active, -> { where(status: :active) }
  scope :recurring, -> { where(auto_renew: true) }
  scope :expiring_soon, -> { where('next_billing_date <= ? AND next_billing_date > ?', 7.days.from_now, Time.current) }
  scope :overdue, -> { where('next_billing_date < ?', Time.current) }
  
  before_save :calculate_next_billing_date
  after_create :create_initial_user_feature
  after_update :handle_status_change
  
  def display_name
    "#{feature.name} - #{plan_name}"
  end
  
  def billing_cycle_display
    billing_cycle.humanize
  end
  
  def status_display
    case status
    when 'active'
      if next_billing_date.present?
        "Active (renews #{next_billing_date.strftime('%b %d, %Y')})"
      else
        'Active'
      end
    when 'cancelled'
      'Cancelled'
    when 'suspended'
      'Suspended'
    when 'inactive'
      'Inactive'
    else
      status.humanize
    end
  end
  
  def price_display
    "₹#{price}/#{billing_cycle}"
  end
  
  def yearly_price
    case billing_cycle
    when 'daily'
      price * 365
    when 'weekly'
      price * 52
    when 'monthly'
      price * 12
    when 'quarterly'
      price * 4
    when 'yearly'
      price
    end
  end
  
  def monthly_price
    case billing_cycle
    when 'daily'
      price * 30
    when 'weekly'
      price * 4.33
    when 'monthly'
      price
    when 'quarterly'
      price / 3
    when 'yearly'
      price / 12
    end
  end
  
  def next_billing_date_display
    return 'N/A' unless next_billing_date
    next_billing_date.strftime('%b %d, %Y')
  end
  
  def days_until_next_billing
    return nil unless next_billing_date
    return 0 if next_billing_date <= Time.current
    
    ((next_billing_date - Time.current) / 1.day).ceil
  end
  
  def can_cancel?
    active? && !cancelled?
  end
  
  def can_suspend?
    active? && !suspended?
  end
  
  def can_reactivate?
    cancelled? || suspended?
  end
  
  def cancel_subscription(reason = nil)
    return false unless can_cancel?
    
    update!(
      status: :cancelled,
      cancelled_at: Time.current,
      cancellation_reason: reason,
      auto_renew: false
    )
  end
  
  def suspend_subscription(reason = nil)
    return false unless can_suspend?
    
    update!(
      status: :suspended,
      suspended_at: Time.current,
      suspension_reason: reason
    )
  end
  
  def reactivate_subscription
    return false unless can_reactivate?
    
    update!(
      status: :active,
      suspended_at: nil,
      suspension_reason: nil,
      cancelled_at: nil,
      cancellation_reason: nil
    )
  end
  
  def renew_subscription
    return false unless active?
    
    # Process payment
    payment_result = process_renewal_payment
    
    if payment_result[:success]
      update!(
        last_billing_date: Time.current,
        next_billing_date: calculate_next_billing_date_from_now,
        billing_count: billing_count + 1
      )
      
      # Extend user feature access
      user_feature = user_features.active.first
      if user_feature
        user_feature.extend_access(billing_cycle_days)
      end
      
      { success: true, message: 'Subscription renewed successfully' }
    else
      { success: false, message: payment_result[:message] }
    end
  end
  
  def process_renewal_payment
    # This would integrate with your payment processor (Razorpay)
    # For now, return success as placeholder
    { success: true, message: 'Payment processed successfully' }
  end
  
  def upgrade_plan(new_plan_name)
    new_plan = feature.pricing_tier_by_name(new_plan_name)
    return { success: false, message: 'Plan not found' } unless new_plan
    
    old_price = price
    new_price = new_plan['price']
    
    # Calculate prorated amount
    prorated_amount = calculate_prorated_upgrade_amount(new_price, old_price)
    
    # Process upgrade payment
    payment_result = process_upgrade_payment(prorated_amount)
    
    if payment_result[:success]
      update!(
        plan_name: new_plan_name,
        price: new_price,
        usage_limit: new_plan['usage_limit'],
        features: new_plan['features']
      )
      
      { success: true, message: 'Plan upgraded successfully' }
    else
      { success: false, message: payment_result[:message] }
    end
  end
  
  def downgrade_plan(new_plan_name)
    new_plan = feature.pricing_tier_by_name(new_plan_name)
    return { success: false, message: 'Plan not found' } unless new_plan
    
    # Downgrades typically take effect at next billing cycle
    update!(
      plan_name: new_plan_name,
      price: new_plan['price'],
      usage_limit: new_plan['usage_limit'],
      features: new_plan['features'],
      effective_date: next_billing_date
    )
    
    { success: true, message: 'Plan will be downgraded at next billing cycle' }
  end
  
  def usage_stats
    {
      current_usage: calculate_current_usage,
      usage_limit: usage_limit,
      usage_percentage: calculate_usage_percentage,
      days_remaining: days_until_next_billing
    }
  end
  
  def within_usage_limits?
    return true unless usage_limit
    
    current_usage = calculate_current_usage
    current_usage <= usage_limit
  end
  
  def usage_warning_threshold_reached?
    return false unless usage_limit
    
    current_usage = calculate_current_usage
    threshold = usage_limit * 0.8 # 80% threshold
    current_usage >= threshold
  end
  
  def usage_critical_threshold_reached?
    return false unless usage_limit
    
    current_usage = calculate_current_usage
    threshold = usage_limit * 0.95 # 95% threshold
    current_usage >= threshold
  end
  
  def billing_history
    # This would return billing history from orders
    orders.where(status: 'paid').order(created_at: :desc)
  end
  
  def total_paid
    orders.where(status: 'paid').sum(:total_amount)
  end
  
  def average_monthly_revenue
    return 0 if billing_count == 0
    
    total_paid / billing_count
  end
  
  private
  
  def calculate_next_billing_date
    return if next_billing_date.present?
    
    self.next_billing_date = calculate_next_billing_date_from_now
  end
  
  def calculate_next_billing_date_from_now
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
  
  def billing_cycle_days
    case billing_cycle
    when 'daily'
      1
    when 'weekly'
      7
    when 'monthly'
      30
    when 'quarterly'
      90
    when 'yearly'
      365
    else
      30
    end
  end
  
  def create_initial_user_feature
    user_features.create!(
      user: user,
      feature: feature,
      status: :active,
      subscription: self,
      expires_at: next_billing_date
    )
  end
  
  def handle_status_change
    case status
    when 'cancelled'
      handle_cancellation
    when 'suspended'
      handle_suspension
    when 'active'
      handle_reactivation
    end
  end
  
  def handle_cancellation
    # Suspend user feature access
    user_features.active.each do |user_feature|
      user_feature.suspend_access(cancellation_reason)
    end
    
    # Send cancellation notification
    # UserMailer.subscription_cancelled(user, self).deliver_later
  end
  
  def handle_suspension
    # Suspend user feature access
    user_features.active.each do |user_feature|
      user_feature.suspend_access(suspension_reason)
    end
    
    # Send suspension notification
    # UserMailer.subscription_suspended(user, self).deliver_later
  end
  
  def handle_reactivation
    # Reactivate user feature access
    user_features.suspended.each do |user_feature|
      user_feature.reactivate_access
    end
    
    # Send reactivation notification
    # UserMailer.subscription_reactivated(user, self).deliver_later
  end
  
  def calculate_prorated_upgrade_amount(new_price, old_price)
    # Calculate prorated amount based on remaining days in billing cycle
    remaining_days = days_until_next_billing
    total_days = billing_cycle_days
    
    price_difference = new_price - old_price
    prorated_amount = (price_difference * remaining_days) / total_days
    
    [prorated_amount, 0].max
  end
  
  def process_upgrade_payment(amount)
    # This would integrate with your payment processor
    # For now, return success as placeholder
    { success: true, message: 'Upgrade payment processed successfully' }
  end
  
  def calculate_current_usage
    # This would be implemented based on specific feature usage tracking
    # For now, return 0 as placeholder
    0
  end
  
  def calculate_usage_percentage
    return 0 unless usage_limit
    
    current_usage = calculate_current_usage
    (current_usage.to_f / usage_limit * 100).round(2)
  end
end
