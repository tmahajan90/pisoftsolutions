class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  rescue ActiveRecord::RecordNotFound
    session[:user_id] = nil
  end

  def logged_in?
    !!current_user
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: 'Please log in to access this page.'
    end
  end

  def find_or_create_user_by_email(email, attributes = {})
    User.find_or_create_by_email(email, attributes)
  end
end
