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
    
    # Calculate current month revenue
    current_month_start = Date.current.beginning_of_month
    @current_month_revenue = Order.where(status: ['paid', 'shipped', 'delivered'])
                                 .where('created_at >= ?', current_month_start)
                                 .sum(:total_amount)
    
    # Calculate revenue growth percentage
    last_month_start = 1.month.ago.beginning_of_month
    last_month_end = 1.month.ago.end_of_month
    last_month_revenue = Order.where(status: ['paid', 'shipped', 'delivered'])
                             .where(created_at: last_month_start..last_month_end)
                             .sum(:total_amount)
    
    if last_month_revenue > 0
      @revenue_growth = (((@current_month_revenue - last_month_revenue) / last_month_revenue) * 100).round(1)
    else
      @revenue_growth = @current_month_revenue > 0 ? 100.0 : 0.0
    end
  end
end
