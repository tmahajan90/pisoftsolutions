class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :phone])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :phone])
  end

  def after_sign_up_path_for(resource)
    # Redirect to a page explaining email confirmation
    flash[:notice] = 'Please check your email and click the confirmation link to activate your account.'
    root_path
  end

  def after_inactive_sign_up_path_for(resource)
    # Redirect to a page explaining email confirmation
    flash[:notice] = 'Please check your email and click the confirmation link to activate your account.'
    root_path
  end
end
