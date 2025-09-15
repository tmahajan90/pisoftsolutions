class OrderMailer < ApplicationMailer
  default from: -> { default_from_email }

  def order_confirmation(order)
    @order = order
    @user = order.user
    @order_items = order.order_items.includes(:product)
    @applied_offers = order.applied_offers
    @order_date = order.created_at.strftime("%B %d, %Y")
    @order_time = order.created_at.strftime("%I:%M %p")
    
    # Set URL options for this email
    ActionMailer::Base.default_url_options[:host] = default_host
    
    mail(
      to: @order.user_email,
      subject: "Order Confirmation - Order ##{@order.id}",
      reply_to: support_email
    ) do |format|
      format.html { render layout: 'mailer' }
      format.text { render layout: 'mailer' }
    end
  end

  def admin_order_notification(order)
    @order = order
    @user = order.user
    @order_items = order.order_items.includes(:product)
    @applied_offers = order.applied_offers
    @order_date = order.created_at.strftime("%B %d, %Y")
    @order_time = order.created_at.strftime("%I:%M %p")
    
    # Set URL options for this email
    ActionMailer::Base.default_url_options[:host] = default_host
    
    # Send to admin email
    admin_email = admin_notification_email
    
    mail(
      to: admin_email,
      subject: "New Order Received - Order ##{@order.id} - ₹#{@order.total_amount}",
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

  def admin_notification_email
    if ENV['ADMIN_EMAIL'].present?
      ENV['ADMIN_EMAIL']
    else
      "admin@pisoftsolutions.in"
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
