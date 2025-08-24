class AdminController < ApplicationController
  before_action :require_admin
  
  layout 'admin'
  
  private
  
  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied. Admin privileges required.'
    end
  end
  
  def admin_dashboard_data
    @total_users = User.count
    @total_orders = Order.count
    @total_revenue = Order.where(status: ['paid', 'shipped', 'delivered']).sum(:total_amount)
    @pending_orders = Order.where(status: 'pending').count
    @new_contacts = Contact.unread.count
    
    @recent_users = User.recent.limit(5)
    @recent_orders = Order.includes(:user).recent.limit(5)
    @recent_contacts = Contact.recent.limit(5)
    
    # Monthly revenue data for charts
    @monthly_revenue = Order.where(status: ['paid', 'shipped', 'delivered'])
                           .where('created_at >= ?', 6.months.ago)
                           .group("DATE_TRUNC('month', created_at)")
                           .sum(:total_amount)
  end
end
