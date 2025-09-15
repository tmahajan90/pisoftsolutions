class Users::ConfirmationsController < Devise::ConfirmationsController
  def after_confirmation_path_for(resource_name, resource)
    # Redirect to login page after successful confirmation
    flash[:notice] = 'Your email has been confirmed successfully! You can now log in.'
    new_user_session_path
  end
end
