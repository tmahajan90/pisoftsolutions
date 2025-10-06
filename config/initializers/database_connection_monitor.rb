# Database Connection Monitor and Auto-Recovery
# This initializer helps prevent database crashes by managing connections

if Rails.env.production?
  # Configure connection pool monitoring
  Rails.application.config.after_initialize do
    # Monitor connection pool health
    ActiveSupport::Notifications.subscribe('connection.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      
      # Log slow queries
      if event.duration > 5000 # 5 seconds
        Rails.logger.warn "Slow query detected: #{event.duration}ms - #{event.payload[:sql]}"
      end
    end
    
    # Monitor connection pool size
    Thread.new do
      loop do
        begin
          pool = ActiveRecord::Base.connection_pool
          if pool.connected?
            size = pool.size
            checked_out = pool.checked_out.size
            available = pool.available.size
            
            Rails.logger.info "Connection Pool Status - Size: #{size}, Checked Out: #{checked_out}, Available: #{available}"
            
            # Alert if pool is getting full
            if checked_out > (size * 0.8)
              Rails.logger.warn "Connection pool is #{((checked_out.to_f / size) * 100).round(1)}% full!"
            end
            
            # Alert if no connections available
            if available == 0
              Rails.logger.error "No database connections available!"
            end
          end
        rescue => e
          Rails.logger.error "Connection monitoring error: #{e.message}"
        end
        
        sleep 30 # Check every 30 seconds
      end
    end
  end
  
  # Configure connection retry logic
  ActiveRecord::Base.connection_pool.class_eval do
    alias_method :original_checkout, :checkout
    
    def checkout(*args)
      retries = 0
      max_retries = 3
      
      begin
        original_checkout(*args)
      rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => e
        if retries < max_retries
          retries += 1
          Rails.logger.warn "Database connection failed, retrying (#{retries}/#{max_retries}): #{e.message}"
          sleep(2 ** retries) # Exponential backoff
          retry
        else
          Rails.logger.error "Database connection failed after #{max_retries} retries: #{e.message}"
          raise
        end
      end
    end
  end
  
  # Configure statement timeout
  ActiveRecord::Base.connection_pool.with_connection do |connection|
    connection.execute("SET statement_timeout = '30s'")
    connection.execute("SET idle_in_transaction_session_timeout = '5min'")
    connection.execute("SET lock_timeout = '10s'")
  end
  
  # Add connection cleanup on application shutdown
  at_exit do
    Rails.logger.info "Cleaning up database connections..."
    ActiveRecord::Base.connection_pool.disconnect!
  end
end
