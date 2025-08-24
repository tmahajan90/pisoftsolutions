class SessionsController < ApplicationController
  def new
    redirect_to root_path if current_user
  end

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to session.delete(:return_to) || root_path, notice: 'Successfully logged in!'
    else
      flash.now[:alert] = 'Invalid email or password'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: 'Successfully logged out!'
  end
end
