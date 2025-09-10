class ApplicationMailer < ActionMailer::Base
  default from: -> { default_from_email }
  layout "mailer"

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
end
