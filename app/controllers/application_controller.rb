class ApplicationController < ActionController::Base
  # Authentication will be handled by individual controllers
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  # Keep legacy helper methods for backward compatibility
  helper_method :logged_in?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :phone])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :phone])
  end

  private

  # Legacy methods for backward compatibility
  # Note: current_user is provided by Devise automatically

  def logged_in?
    user_signed_in?
  end

  def require_login
    unless user_signed_in?
      redirect_to new_user_session_path, alert: 'Please log in to access this page.'
    end
  end

  def find_or_create_user_by_email(email, attributes = {})
    User.find_or_create_by_email(email, attributes)
  end
end
