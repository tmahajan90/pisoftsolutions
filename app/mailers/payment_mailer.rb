class PaymentMailer < ApplicationMailer
  default from: -> { default_from_email }

  def payment_success(order)
    @order = order
    @user = order.user
    @order_items = order.order_items.includes(:product)
    @applied_offers = order.applied_offers
    
    # Set URL options for this email
    ActionMailer::Base.default_url_options[:host] = default_host
    
    mail(
      to: @order.user_email,
      subject: "Payment Successful - Order ##{@order.id} Confirmed",
      reply_to: support_email
    ) do |format|
      format.html { render layout: 'mailer' }
      format.text { render layout: 'mailer' }
    end
  end

  def payment_failed(order)
    @order = order
    @user = order.user
    @order_items = order.order_items.includes(:product)
    
    # Set URL options for this email
    ActionMailer::Base.default_url_options[:host] = default_host
    
    mail(
      to: @order.user_email,
      subject: "Payment Failed - Order ##{@order.id}",
      reply_to: support_email
    ) do |format|
      format.html { render layout: 'mailer' }
      format.text { render layout: 'mailer' }
    end
  end

  def payment_reminder(order)
    @order = order
    @user = order.user
    @order_items = order.order_items.includes(:product)
    @time_remaining = calculate_time_remaining(order)
    
    # Set URL options for this email
    ActionMailer::Base.default_url_options[:host] = default_host
    
    mail(
      to: @order.user_email,
      subject: "Complete Your Payment - Order ##{@order.id}",
      reply_to: support_email
    ) do |format|
      format.html { render layout: 'mailer' }
      format.text { render layout: 'mailer' }
    end
  end

  private

  def default_from_email
    if ENV['SMTP_USERNAME'].present?
      ENV['SMTP_USERNAME']
    elsif ENV['DOMAIN'].present?
      "noreply@#{ENV['DOMAIN']}"
    else
      "noreply@pisoftsolutions.in"
    end
  end

  def support_email
    if ENV['SUPPORT_EMAIL'].present?
      ENV['SUPPORT_EMAIL']
    elsif ENV['DOMAIN'].present?
      "support@#{ENV['DOMAIN']}"
    else
      "support@pisoftsolutions.in"
    end
  end

  def calculate_time_remaining(order)
    return nil unless order.payment_pending?
    
    time_elapsed = Time.current - order.created_at
    time_remaining = 15.minutes - time_elapsed
    
    if time_remaining > 0
      "#{(time_remaining / 1.minute).ceil} minutes"
    else
      "expired"
    end
  end

  def default_host
    if ENV['DOMAIN'].present?
      ENV['DOMAIN']
    elsif Rails.env.production?
      'pisoftsolutions.in'
    else
      'localhost:3000'
    end
  end
end
