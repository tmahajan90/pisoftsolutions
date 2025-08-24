class Admin::UsersController < AdminController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.includes(:orders)
                 .order(created_at: :desc)
                 .limit(20)
    
    if params[:search].present?
      @users = @users.where("name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    if params[:role].present?
      @users = @users.where(role: params[:role])
    end
  end

  def show
    @orders = @user.orders.includes(:order_items, :products).recent
    @total_spent = @user.total_spent
    @order_count = @user.total_orders
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: 'User updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.admin? && User.admins.count == 1
      redirect_to admin_users_path, alert: 'Cannot delete the last admin user.'
    else
      @user.destroy
      redirect_to admin_users_path, notice: 'User deleted successfully.'
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone, :role, :password, :password_confirmation)
  end
end
