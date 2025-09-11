class SubscriptionService
  include ActiveModel::Model
  
  attr_accessor :user, :feature, :plan_name, :payment_method, :coupon_code
  
  def initialize(user:, feature:, plan_name:, payment_method: 'razorpay', coupon_code: nil)
    @user = user
    @feature = feature
    @plan_name = plan_name
    @payment_method = payment_method
    @coupon_code = coupon_code
  end
  
  def create_subscription
    return { success: false, message: 'Invalid user' } unless user
    return { success: false, message: 'Invalid feature' } unless feature
    return { success: false, message: 'Feature not available' } unless feature.active?
    
    plan = feature.pricing_tier_by_name(plan_name)
    return { success: false, message: 'Invalid plan' } unless plan
    
    # Check if user already has access
    if user.has_feature_access?(feature)
      return { success: false, message: 'You already have access to this feature' }
    end
    
    # Calculate final price with coupon
    final_price = calculate_final_price(plan)
    
    # Create subscription
    subscription = create_subscription_record(plan, final_price)
    
    if subscription.persisted?
      # Process payment
      payment_result = process_payment(subscription, final_price)
      
      if payment_result[:success]
        activate_subscription(subscription)
        { success: true, subscription: subscription, message: 'Subscription created successfully' }
      else
        subscription.destroy
        { success: false, message: payment_result[:message] }
      end
    else
      { success: false, message: subscription.errors.full_messages.join(', ') }
    end
  end
  
  def start_trial
    return { success: false, message: 'Invalid user' } unless user
    return { success: false, message: 'Invalid feature' } unless feature
    return { success: false, message: 'Feature not available' } unless feature.active?
    return { success: false, message: 'Trial not available' } unless feature.has_trial?
    return { success: false, message: 'Cannot start trial' } unless feature.can_user_trial?(user)
    
    if feature.start_trial_for_user(user)
      { success: true, message: "Trial started! You have #{feature.trial_duration} to explore this feature." }
    else
      { success: false, message: 'Failed to start trial' }
    end
  end
  
  def cancel_subscription(subscription, reason = nil)
    return { success: false, message: 'Invalid subscription' } unless subscription
    return { success: false, message: 'Cannot cancel subscription' } unless subscription.can_cancel?
    
    if subscription.cancel_subscription(reason)
      { success: true, message: 'Subscription cancelled successfully' }
    else
      { success: false, message: 'Failed to cancel subscription' }
    end
  end
  
  def upgrade_subscription(subscription, new_plan_name)
    return { success: false, message: 'Invalid subscription' } unless subscription
    return { success: false, message: 'Invalid plan' } unless feature.pricing_tier_by_name(new_plan_name)
    
    result = subscription.upgrade_plan(new_plan_name)
    
    if result[:success]
      { success: true, message: result[:message] }
    else
      { success: false, message: result[:message] }
    end
  end
  
  def downgrade_subscription(subscription, new_plan_name)
    return { success: false, message: 'Invalid subscription' } unless subscription
    return { success: false, message: 'Invalid plan' } unless feature.pricing_tier_by_name(new_plan_name)
    
    result = subscription.downgrade_plan(new_plan_name)
    
    if result[:success]
      { success: true, message: result[:message] }
    else
      { success: false, message: result[:message] }
    end
  end
  
  def renew_subscription(subscription)
    return { success: false, message: 'Invalid subscription' } unless subscription
    return { success: false, message: 'Subscription not active' } unless subscription.active?
    
    result = subscription.renew_subscription
    
    if result[:success]
      { success: true, message: result[:message] }
    else
      { success: false, message: result[:message] }
    end
  end
  
  def suspend_subscription(subscription, reason = nil)
    return { success: false, message: 'Invalid subscription' } unless subscription
    return { success: false, message: 'Cannot suspend subscription' } unless subscription.can_suspend?
    
    if subscription.suspend_subscription(reason)
      { success: true, message: 'Subscription suspended successfully' }
    else
      { success: false, message: 'Failed to suspend subscription' }
    end
  end
  
  def reactivate_subscription(subscription)
    return { success: false, message: 'Invalid subscription' } unless subscription
    return { success: false, message: 'Cannot reactivate subscription' } unless subscription.can_reactivate?
    
    if subscription.reactivate_subscription
      { success: true, message: 'Subscription reactivated successfully' }
    else
      { success: false, message: 'Failed to reactivate subscription' }
    end
  end
  
  def process_billing_cycle
    # This method would be called by a background job to process recurring billing
    subscriptions_to_renew = Subscription.active
                                        .where('next_billing_date <= ?', Time.current)
                                        .where(auto_renew: true)
    
    results = []
    
    subscriptions_to_renew.each do |subscription|
      result = renew_subscription(subscription)
      results << { subscription: subscription, result: result }
    end
    
    results
  end
  
  def send_usage_warnings
    # Send warnings for users approaching usage limits
    subscriptions = Subscription.active.where.not(usage_limit: nil)
    
    subscriptions.each do |subscription|
      if subscription.usage_critical_threshold_reached?
        # Send critical usage warning
        # UserMailer.usage_critical_warning(subscription.user, subscription).deliver_later
      elsif subscription.usage_warning_threshold_reached?
        # Send usage warning
        # UserMailer.usage_warning(subscription.user, subscription).deliver_later
      end
    end
  end
  
  def send_expiration_notices
    # Send notices for expiring subscriptions
    expiring_subscriptions = Subscription.active
                                       .where('next_billing_date <= ? AND next_billing_date > ?', 
                                              7.days.from_now, Time.current)
    
    expiring_subscriptions.each do |subscription|
      # UserMailer.subscription_expiring_soon(subscription.user, subscription).deliver_later
    end
  end
  
  def handle_failed_payments
    # Handle subscriptions with failed payments
    failed_subscriptions = Subscription.active
                                     .where('next_billing_date < ?', Time.current)
                                     .where(auto_renew: true)
    
    failed_subscriptions.each do |subscription|
      # Attempt to retry payment
      payment_result = process_payment(subscription, subscription.price)
      
      if payment_result[:success]
        renew_subscription(subscription)
      else
        # Suspend subscription after multiple failed attempts
        suspend_subscription(subscription, 'Payment failed')
      end
    end
  end
  
  private
  
  def calculate_final_price(plan)
    base_price = plan['price']
    
    if coupon_code.present?
      coupon = Coupon.find_by(code: coupon_code, active: true)
      if coupon && coupon.valid_for_amount?(base_price)
        base_price = coupon.apply_discount(base_price)
      end
    end
    
    base_price
  end
  
  def create_subscription_record(plan, final_price)
    subscription = feature.subscriptions.build(
      user: user,
      plan_name: plan['name'],
      price: final_price,
      billing_cycle: plan['billing_cycle'] || 'monthly',
      status: :inactive, # Will be activated after payment
      auto_renew: true,
      usage_limit: plan['usage_limit'],
      features: plan['features'],
      started_at: Time.current
    )
    
    subscription.save
    subscription
  end
  
  def process_payment(subscription, amount)
    case payment_method
    when 'razorpay'
      process_razorpay_payment(subscription, amount)
    else
      { success: false, message: 'Invalid payment method' }
    end
  end
  
  def process_razorpay_payment(subscription, amount)
    # Integrate with your existing RazorpayService
    razorpay_service = RazorpayService.new
    result = razorpay_service.create_order(amount, 'INR', "subscription_#{subscription.id}")
    
    if result[:success]
      subscription.update(razorpay_order_id: result[:order_id])
      { success: true, order_id: result[:order_id] }
    else
      { success: false, message: result[:message] }
    end
  end
  
  def activate_subscription(subscription)
    subscription.update!(status: :active)
    
    # Create or update user feature
    user_feature = user.user_features.find_or_initialize_by(feature: feature)
    user_feature.assign_attributes(
      status: :active,
      subscription: subscription,
      expires_at: subscription.next_billing_date
    )
    user_feature.save!
    
    # Send confirmation email
    # UserMailer.subscription_confirmed(user, subscription).deliver_later
  end
end
