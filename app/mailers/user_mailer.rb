class UserMailer < ApplicationMailer
  default from: -> { default_from_email }

  def welcome_email(user)
    @user = user
    @signup_date = user.created_at.strftime("%B %d, %Y")
    @signup_time = user.created_at.strftime("%I:%M %p")
    
    # Set URL options for this email
    ActionMailer::Base.default_url_options[:host] = default_host
    
    mail(
      to: @user.email,
      subject: "Welcome to PiSoftSolutions - Your Account is Ready!",
      reply_to: support_email
    ) do |format|
      format.html { render layout: 'mailer' }
      format.text { render layout: 'mailer' }
    end
  end

  def admin_signup_notification(user)
    @user = user
    @signup_date = user.created_at.strftime("%B %d, %Y")
    @signup_time = user.created_at.strftime("%I:%M %p")
    @user_agent = @user.user_agent if @user.respond_to?(:user_agent)
    @ip_address = @user.ip_address if @user.respond_to?(:ip_address)
    
    # Set URL options for this email
    ActionMailer::Base.default_url_options[:host] = default_host
    
    # Send to admin email
    admin_email = admin_notification_email
    
    mail(
      to: admin_email,
      subject: "New User Signup - #{@user.name} (#{@user.email})",
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
