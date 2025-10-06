class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token
  # skip_before_action :authenticate_user!, if: :devise_controller?
  
  def index
    health_status = {
      status: 'healthy',
      timestamp: Time.current.iso8601,
      environment: Rails.env,
      database: database_status,
      redis: redis_status,
      version: Rails.version
    }
    
    render json: health_status, status: :ok
  end
  
  private
  
  def database_status
    connection = ActiveRecord::Base.connection
    connection.execute('SELECT 1')
    
    # Get connection pool stats
    pool = connection.pool
    pool_stats = {
      size: pool.size,
      checked_out: pool.checked_out.size,
      available: pool.available.size,
      usage_percentage: ((pool.checked_out.size.to_f / pool.size) * 100).round(2)
    }
    
    # Get database stats
    db_stats = connection.execute(<<~SQL).first
      SELECT 
        (SELECT count(*) FROM pg_stat_activity WHERE state = 'active') as active_connections,
        (SELECT count(*) FROM pg_locks WHERE NOT granted) as blocked_locks,
        (SELECT count(*) FROM pg_stat_activity WHERE state = 'idle in transaction') as idle_in_transaction
    SQL
    
    {
      status: 'connected',
      pool: pool_stats,
      database: {
        active_connections: db_stats['active_connections'],
        blocked_locks: db_stats['blocked_locks'],
        idle_in_transaction: db_stats['idle_in_transaction']
      }
    }
  rescue => e
    {
      status: 'error',
      error: e.message,
      pool: { size: 0, checked_out: 0, available: 0, usage_percentage: 0 },
      database: { active_connections: 0, blocked_locks: 0, idle_in_transaction: 0 }
    }
  end
  
  def redis_status
    Redis.new(url: ENV['REDIS_URL']).ping
    'connected'
  rescue => e
    'error'
  end
end
