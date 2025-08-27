class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!, if: :devise_controller?
  
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
    ActiveRecord::Base.connection.execute('SELECT 1')
    'connected'
  rescue => e
    'error'
  end
  
  def redis_status
    Redis.new(url: ENV['REDIS_URL']).ping
    'connected'
  rescue => e
    'error'
  end
end
