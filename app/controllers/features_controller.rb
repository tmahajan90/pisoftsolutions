class FeaturesController < ApplicationController
  before_action :require_login, except: [:index, :show]
  before_action :set_feature, only: [:show, :subscribe, :start_trial, :cancel_subscription]
  before_action :ensure_feature_access, only: [:show]
  
  def index
    @features = Feature.active.includes(:user_features)
    @featured_features = @features.featured
    @features_by_category = @features.group_by(&:category)
    
    if current_user
      @user_features = current_user.user_features.includes(:feature, :subscription)
      @active_features = current_user.active_features
      @trial_features = current_user.trial_features
      @available_features = current_user.available_features
    end
  end
  
  def show
    @related_features = @feature.class.by_category(@feature.category)
                               .where.not(id: @feature.id)
                               .active
                               .limit(4)
    
    if current_user
      @user_feature = current_user.user_features.find_by(feature: @feature)
      @subscription = current_user.feature_subscription(@feature)
      @can_trial = @feature.can_user_trial?(current_user)
      @can_subscribe = @user_feature.nil? || @user_feature.status == 'expired'
    end
  end
  
  def subscribe
    plan_name = params[:plan_name]
    
    unless plan_name
      redirect_to @feature, alert: 'Please select a plan.'
      return
    end
    
    plan = @feature.pricing_tier_by_name(plan_name)
    unless plan
      redirect_to @feature, alert: 'Invalid plan selected.'
      return
    end
    
    # Create subscription
    subscription = current_user.subscribe_to_feature(@feature, plan_name)
    
    if subscription
      # Process payment (integrate with Razorpay)
      payment_result = process_subscription_payment(subscription, plan)
      
      if payment_result[:success]
        redirect_to subscription_path(subscription), notice: 'Successfully subscribed to feature!'
      else
        subscription.destroy
        redirect_to @feature, alert: "Payment failed: #{payment_result[:message]}"
      end
    else
      redirect_to @feature, alert: 'Failed to create subscription.'
    end
  end
  
  def start_trial
    unless @feature.can_user_trial?(current_user)
      redirect_to @feature, alert: 'Trial not available for this feature.'
      return
    end
    
    if current_user.start_trial_for_feature(@feature)
      redirect_to @feature, notice: "Trial started! You have #{@feature.trial_duration} to explore this feature."
    else
      redirect_to @feature, alert: 'Failed to start trial.'
    end
  end
  
  def cancel_subscription
    subscription = current_user.feature_subscription(@feature)
    
    unless subscription
      redirect_to @feature, alert: 'No active subscription found.'
      return
    end
    
    reason = params[:reason]
    if subscription.cancel_subscription(reason)
      redirect_to @feature, notice: 'Subscription cancelled successfully.'
    else
      redirect_to @feature, alert: 'Failed to cancel subscription.'
    end
  end
  
  def my_features
    @active_features = current_user.active_features.includes(:user_features, :subscriptions)
    @trial_features = current_user.trial_features.includes(:user_features)
    @expired_features = current_user.expired_features.includes(:user_features)
    @suspended_features = current_user.suspended_features.includes(:user_features)
    
    @usage_summary = current_user.usage_summary
  end
  
  def dashboard
    @features = current_user.active_features.includes(:user_features, :subscriptions)
    @recent_activity = get_recent_activity
    @usage_stats = get_usage_stats
    @billing_info = get_billing_info
  end
  
  private
  
  def set_feature
    @feature = Feature.find_by(slug: params[:id]) || Feature.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to features_path, alert: 'Feature not found.'
  end
  
  def ensure_feature_access
    return if @feature.status == 'active'
    
    if @feature.status == 'coming_soon'
      redirect_to features_path, notice: 'This feature is coming soon!'
    elsif @feature.status == 'inactive'
      redirect_to features_path, alert: 'This feature is currently unavailable.'
    end
  end
  
  def process_subscription_payment(subscription, plan)
    # This would integrate with your existing Razorpay service
    # For now, return success as placeholder
    
    # Example integration:
    # razorpay_service = RazorpayService.new
    # result = razorpay_service.create_order(plan['price'], 'INR', "subscription_#{subscription.id}")
    # 
    # if result[:success]
    #   subscription.update(razorpay_order_id: result[:order_id])
    #   { success: true, order_id: result[:order_id] }
    # else
    #   { success: false, message: result[:message] }
    # end
    
    { success: true, order_id: "order_#{subscription.id}_#{Time.current.to_i}" }
  end
  
  def get_recent_activity
    # Get recent user activity across features
    activities = []
    
    # Recent subscriptions
    current_user.subscriptions.recent.limit(5).each do |subscription|
      activities << {
        type: 'subscription',
        feature: subscription.feature,
        message: "Subscribed to #{subscription.feature.name}",
        date: subscription.created_at
      }
    end
    
    # Recent trial starts
    current_user.user_features.trial.recent.limit(5).each do |user_feature|
      activities << {
        type: 'trial',
        feature: user_feature.feature,
        message: "Started trial for #{user_feature.feature.name}",
        date: user_feature.trial_started_at
      }
    end
    
    activities.sort_by { |activity| activity[:date] }.reverse.first(10)
  end
  
  def get_usage_stats
    {
      total_features: current_user.active_features.count,
      total_trials: current_user.user_features.trial.count,
      total_spent: current_user.subscriptions.active.sum(&:total_paid),
      monthly_revenue: current_user.total_monthly_revenue
    }
  end
  
  def get_billing_info
    {
      next_billing_date: current_user.subscriptions.active.minimum(:next_billing_date),
      total_monthly: current_user.total_monthly_revenue,
      total_yearly: current_user.total_yearly_revenue,
      auto_renew_count: current_user.subscriptions.recurring.count
    }
  end
end
