module FeatureAuthorization
  extend ActiveSupport::Concern
  
  included do
    before_action :check_feature_access, if: :feature_required?
  end
  
  private
  
  def check_feature_access
    feature = get_required_feature
    
    unless feature
      redirect_to features_path, alert: 'Feature not found.'
      return
    end
    
    unless current_user&.can_access_feature?(feature)
      if current_user&.has_feature_access?(feature)
        redirect_to features_path, alert: 'Your access to this feature has expired or been suspended.'
      else
        redirect_to feature_path(feature), alert: 'You need to subscribe to access this feature.'
      end
    end
  end
  
  def get_required_feature
    # Override this method in controllers that include this concern
    # Return the feature object that is required for the current action
    nil
  end
  
  def feature_required?
    # Override this method in controllers that include this concern
    # Return true if the current action requires feature access
    false
  end
  
  # Helper methods for use in controllers and views
  def require_feature_access(feature)
    unless current_user&.can_access_feature?(feature)
      redirect_to feature_path(feature), alert: 'You need to subscribe to access this feature.'
    end
  end
  
  def require_feature_trial_or_access(feature)
    unless current_user&.can_access_feature?(feature) || current_user&.has_feature_access?(feature)
      redirect_to feature_path(feature), alert: 'You need to subscribe or start a trial to access this feature.'
    end
  end
  
  def check_usage_limits(feature)
    user_feature = current_user.user_features.find_by(feature: feature)
    return true unless user_feature&.subscription
    
    unless user_feature.within_usage_limits?
      redirect_to feature_path(feature), alert: 'You have reached your usage limit for this feature.'
      return false
    end
    
    if user_feature.usage_critical_threshold_reached?
      flash.now[:warning] = 'You are approaching your usage limit for this feature.'
    elsif user_feature.usage_warning_threshold_reached?
      flash.now[:notice] = 'You are approaching your usage limit for this feature.'
    end
    
    true
  end
  
  def log_feature_usage(feature, action = nil, metadata = {})
    return unless current_user&.can_access_feature?(feature)
    
    # Log feature usage for analytics and billing
    # This could be stored in a separate FeatureUsage model
    Rails.logger.info "Feature Usage: User #{current_user.id} used #{feature.name} - Action: #{action} - Metadata: #{metadata}"
  end
  
  def get_user_feature_status(feature)
    return 'not_available' unless feature&.active?
    return 'admin_access' if current_user&.admin?
    
    user_feature = current_user&.user_features&.find_by(feature: feature)
    return 'not_purchased' unless user_feature
    
    case user_feature.status
    when 'active'
      if user_feature.expires_at && user_feature.expires_at <= Time.current
        'expired'
      else
        'active'
      end
    when 'trial'
      if user_feature.trial_ends_at && user_feature.trial_ends_at <= Time.current
        'trial_expired'
      else
        'trial'
      end
    when 'expired'
      'expired'
    when 'suspended'
      'suspended'
    else
      'inactive'
    end
  end
  
  def can_user_trial_feature?(feature)
    return false unless feature&.active?
    return false unless feature.has_trial?
    return false unless current_user
    
    feature.can_user_trial?(current_user)
  end
  
  def get_feature_pricing_info(feature)
    return nil unless feature&.active?
    
    {
      base_price: feature.base_price,
      min_price: feature.min_price,
      max_price: feature.max_price,
      price_range: feature.price_range_display,
      has_trial: feature.has_trial?,
      trial_duration: feature.trial_duration,
      pricing_tiers: feature.available_pricing_tiers
    }
  end
  
  def get_user_subscription_info(feature)
    return nil unless current_user
    
    subscription = current_user.feature_subscription(feature)
    return nil unless subscription
    
    {
      plan_name: subscription.plan_name,
      price: subscription.price,
      billing_cycle: subscription.billing_cycle,
      status: subscription.status,
      next_billing_date: subscription.next_billing_date,
      auto_renew: subscription.auto_renew,
      usage_limit: subscription.usage_limit,
      current_usage: subscription.calculate_current_usage,
      usage_percentage: subscription.calculate_usage_percentage
    }
  end
  
  # Methods for handling feature-specific actions
  def handle_feature_action(feature, action, params = {})
    return { success: false, message: 'Feature access required' } unless current_user&.can_access_feature?(feature)
    return { success: false, message: 'Usage limit reached' } unless check_usage_limits(feature)
    
    # Log the action
    log_feature_usage(feature, action, params)
    
    # Execute the feature-specific action
    execute_feature_action(feature, action, params)
  end
  
  def execute_feature_action(feature, action, params)
    # Override this method in controllers to handle specific feature actions
    { success: true, message: 'Action completed successfully' }
  end
  
  # Helper for views
  def feature_access_badge(feature)
    status = get_user_feature_status(feature)
    
    case status
    when 'active'
      content_tag(:span, 'Active', class: 'badge badge-success')
    when 'trial'
      content_tag(:span, 'Trial', class: 'badge badge-warning')
    when 'expired'
      content_tag(:span, 'Expired', class: 'badge badge-danger')
    when 'suspended'
      content_tag(:span, 'Suspended', class: 'badge badge-secondary')
    when 'not_purchased'
      content_tag(:span, 'Subscribe', class: 'badge badge-primary')
    else
      content_tag(:span, 'Unavailable', class: 'badge badge-light')
    end
  end
  
  def feature_access_button(feature)
    status = get_user_feature_status(feature)
    
    case status
    when 'active'
      link_to 'Access Feature', feature_path(feature), class: 'btn btn-success'
    when 'trial'
      link_to 'Continue Trial', feature_path(feature), class: 'btn btn-warning'
    when 'expired', 'not_purchased'
      if can_user_trial_feature?(feature)
        link_to 'Start Trial', feature_path(feature, action: 'start_trial'), 
                method: :post, class: 'btn btn-primary'
      else
        link_to 'Subscribe', feature_path(feature), class: 'btn btn-primary'
      end
    when 'suspended'
      link_to 'Reactivate', feature_path(feature, action: 'reactivate'), 
              method: :post, class: 'btn btn-warning'
    else
      content_tag(:span, 'Unavailable', class: 'btn btn-secondary disabled')
    end
  end
end
