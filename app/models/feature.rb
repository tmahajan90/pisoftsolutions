class Feature < ApplicationRecord
  has_many :subscriptions, dependent: :destroy
  has_many :user_features, dependent: :destroy
  has_many :users, through: :user_features
  
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :description, presence: true
  validates :category, presence: true
  validates :base_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  enum status: { active: 0, inactive: 1, coming_soon: 2 }
  enum category: { 
    communication: 0,    # WhatsApp, SMS, Email marketing
    analytics: 1,        # Reports, dashboards, insights
    automation: 2,       # Chatbots, workflows, triggers
    crm: 3,             # Lead management, customer tracking
    ecommerce: 4,       # Product management, inventory
    productivity: 5,    # Task management, scheduling
    integration: 6      # API, webhooks, third-party
  }
  
  scope :active, -> { where(status: :active) }
  scope :by_category, ->(category) { where(category: category) }
  scope :featured, -> { where(featured: true) }
  
  # Serialize pricing tiers as JSON
  serialize :pricing_tiers, coder: JSON, default: []
  serialize :features_list, coder: JSON, default: []
  serialize :requirements, coder: JSON, default: []
  
  before_save :ensure_slug_format
  before_save :ensure_pricing_tiers_array
  before_save :ensure_features_list_array
  before_save :ensure_requirements_array
  
  def self.find_by_slug(slug)
    find_by(slug: slug.to_s.downcase)
  end
  
  def display_name
    name
  end
  
  def icon_class
    icon.presence || default_icon_for_category
  end
  
  def has_trial?
    trial_days.present? && trial_days > 0
  end
  
  def trial_duration
    return nil unless has_trial?
    "#{trial_days} #{'day'.pluralize(trial_days)}"
  end
  
  def base_pricing_tier
    pricing_tiers.find { |tier| tier['is_default'] } || pricing_tiers.first
  end
  
  def pricing_tier_by_name(tier_name)
    pricing_tiers.find { |tier| tier['name'] == tier_name }
  end
  
  def available_pricing_tiers
    pricing_tiers.select { |tier| tier['active'] }
  end
  
  def min_price
    available_pricing_tiers.map { |tier| tier['price'] }.min || base_price
  end
  
  def max_price
    available_pricing_tiers.map { |tier| tier['price'] }.max || base_price
  end
  
  def price_range_display
    if min_price == max_price
      "₹#{min_price}"
    else
      "₹#{min_price} - ₹#{max_price}"
    end
  end
  
  def can_user_access?(user)
    return false unless user
    return true if user.admin?
    
    user_features.exists?(user: user, status: :active)
  end
  
  def user_subscription(user)
    subscriptions.joins(:user_features)
                .where(user_features: { user: user, status: :active })
                .first
  end
  
  def user_feature_status(user)
    user_feature = user_features.find_by(user: user)
    return 'not_purchased' unless user_feature
    
    case user_feature.status
    when 'active'
      'active'
    when 'trial'
      'trial'
    when 'expired'
      'expired'
    when 'suspended'
      'suspended'
    else
      'inactive'
    end
  end
  
  def user_has_trialed?(user)
    return false unless user
    user_features.exists?(user: user, trial_used: true)
  end
  
  def can_user_trial?(user)
    return false unless has_trial?
    return false if user_has_trialed?(user)
    return false if can_user_access?(user)
    true
  end
  
  def start_trial_for_user(user)
    return false unless can_user_trial?(user)
    
    user_feature = user_features.find_or_initialize_by(user: user)
    user_feature.assign_attributes(
      status: :trial,
      trial_used: true,
      trial_started_at: Time.current,
      trial_ends_at: trial_days.days.from_now,
      expires_at: trial_days.days.from_now
    )
    
    user_feature.save
  end
  
  def convert_trial_to_subscription(user, subscription_plan)
    user_feature = user_features.find_by(user: user, status: :trial)
    return false unless user_feature
    
    # Create subscription
    subscription = subscriptions.create!(
      user: user,
      plan_name: subscription_plan['name'],
      price: subscription_plan['price'],
      billing_cycle: subscription_plan['billing_cycle'] || 'monthly',
      status: :active,
      started_at: Time.current
    )
    
    # Update user feature
    user_feature.update!(
      status: :active,
      subscription: subscription,
      expires_at: calculate_expiry_date(subscription_plan['billing_cycle'])
    )
    
    subscription
  end
  
  def suspend_user_access(user, reason = nil)
    user_feature = user_features.find_by(user: user)
    return false unless user_feature
    
    user_feature.update!(
      status: :suspended,
      suspended_at: Time.current,
      suspension_reason: reason
    )
  end
  
  def reactivate_user_access(user)
    user_feature = user_features.find_by(user: user, status: :suspended)
    return false unless user_feature
    
    user_feature.update!(
      status: :active,
      suspended_at: nil,
      suspension_reason: nil
    )
  end
  
  def expire_user_access(user)
    user_feature = user_features.find_by(user: user)
    return false unless user_feature
    
    user_feature.update!(
      status: :expired,
      expires_at: Time.current
    )
  end
  
  private
  
  def ensure_slug_format
    self.slug = name.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '') if slug.blank?
  end
  
  def ensure_pricing_tiers_array
    self.pricing_tiers = [] if pricing_tiers.nil?
  end
  
  def ensure_features_list_array
    self.features_list = [] if features_list.nil?
  end
  
  def ensure_requirements_array
    self.requirements = [] if requirements.nil?
  end
  
  def default_icon_for_category
    case category
    when 'communication'
      'fas fa-comments'
    when 'analytics'
      'fas fa-chart-bar'
    when 'automation'
      'fas fa-robot'
    when 'crm'
      'fas fa-users'
    when 'ecommerce'
      'fas fa-shopping-cart'
    when 'productivity'
      'fas fa-tasks'
    when 'integration'
      'fas fa-plug'
    else
      'fas fa-cube'
    end
  end
  
  def calculate_expiry_date(billing_cycle)
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
