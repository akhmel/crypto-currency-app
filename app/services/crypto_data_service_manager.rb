require 'singleton'
require 'logger'

class CryptoDataServiceManager
  include Singleton

  def initialize
    @logger = Logger.new(STDOUT)
    @publisher_service = nil
    @consumer_service = nil
    @publisher_thread = nil
    @consumer_thread = nil
    @initialized = false
  end

  def initialize_services
    return if @initialized
    
    @logger.info "Initializing Crypto Data Services..."
    
    begin
      # Initialize publisher service
      @publisher_service = KafkaPublisherService.instance
      
      # Initialize consumer service
      @consumer_service = KafkaConsumerService.instance
      
      @initialized = true
      @logger.info "Crypto Data Services initialized successfully"
      
    rescue => e
      @logger.error "Failed to initialize Crypto Data Services: #{e.message}"
      @logger.error e.backtrace.join("\n")
      raise e
    end
  end

  def start_all_services
    return unless @initialized
    
    @logger.info "Starting all Crypto Data Services in separate threads..."
    
    begin
      # Start publisher service in a separate thread
      @publisher_thread = Thread.new do
        Thread.current.name = "KafkaPublisherService"
        @logger.info "Starting Kafka Publisher Service in thread: #{Thread.current.name}"
        
        begin
          @publisher_service.start
        rescue => e
          @logger.error "Kafka Publisher Service thread error: #{e.message}"
          @logger.error e.backtrace.join("\n")
        end
      end
      
      # Start consumer service in a separate thread
      @consumer_thread = Thread.new do
        Thread.current.name = "KafkaConsumerService"
        @logger.info "Starting Kafka Consumer Service in thread: #{Thread.current.name}"
        
        begin
          @consumer_service.start
        rescue => e
          @logger.error "Kafka Consumer Service thread error: #{e.message}"
          @logger.error e.backtrace.join("\n")
        end
      end
      
      # Wait a moment for threads to start
      sleep 2
      
      @logger.info "All Crypto Data Services started successfully in separate threads"
      
    rescue => e
      @logger.error "Failed to start Crypto Data Services: #{e.message}"
      @logger.error e.backtrace.join("\n")
      stop_all_services
      raise e
    end
  end

  def stop_all_services
    @logger.info "Stopping all Crypto Data Services..."
    
    # Stop publisher service
    if @publisher_service
      @logger.info "Stopping Kafka Publisher Service..."
      @publisher_service.stop
    end
    
    # Stop consumer service
    if @consumer_service
      @logger.info "Stopping Kafka Consumer Service..."
      @consumer_service.stop
    end
    
    # Wait for threads to finish
    if @publisher_thread && @publisher_thread.alive?
      @logger.info "Waiting for Publisher Service thread to finish..."
      @publisher_thread.join(10) # Wait up to 10 seconds
      if @publisher_thread.alive?
        @logger.warn "Publisher Service thread did not finish gracefully, terminating..."
        @publisher_thread.terminate
      end
    end
    
    if @consumer_thread && @consumer_thread.alive?
      @logger.info "Waiting for Consumer Service thread to finish..."
      @consumer_thread.join(10) # Wait up to 10 seconds
      if @consumer_thread.alive?
        @logger.warn "Consumer Service thread did not finish gracefully, terminating..."
        @consumer_thread.terminate
      end
    end
    
    @publisher_thread = nil
    @consumer_thread = nil
    
    @logger.info "All Crypto Data Services stopped"
  end

  def restart_all_services
    @logger.info "Restarting all Crypto Data Services..."
    stop_all_services
    sleep 2 # Wait a bit before restarting
    start_all_services
  end

  def services_status
    {
      initialized: @initialized,
      publisher: {
        running: @publisher_service&.running? || false,
        thread_alive: @publisher_thread&.alive? || false,
        thread_name: @publisher_thread&.name
      },
      consumer: {
        running: @consumer_service&.running? || false,
        thread_alive: @consumer_thread&.alive? || false,
        thread_name: @consumer_thread&.name
      },
      timestamp: Time.now.to_i
    }
  end

  def health_check
    return { error: 'Services not initialized' } unless @initialized
    
    {
      publisher: {
        service_running: @publisher_service&.running? || false,
        thread_alive: @publisher_thread&.alive? || false,
        thread_name: @publisher_thread&.name
      },
      consumer: @consumer_service&.health_check,
      overall_status: overall_status,
      timestamp: Time.now.to_i
    }
  end

  def publisher_service
    @publisher_service
  end

  def consumer_service
    @consumer_service
  end

  # Get thread information for debugging
  def thread_info
    {
      publisher_thread: {
        alive: @publisher_thread&.alive? || false,
        name: @publisher_thread&.name,
        status: @publisher_thread&.status,
        backtrace: @publisher_thread&.backtrace&.first(5)
      },
      consumer_thread: {
        alive: @consumer_thread&.alive? || false,
        name: @consumer_thread&.name,
        status: @consumer_thread&.status,
        backtrace: @consumer_thread&.backtrace&.first(5)
      }
    }
  end

  private

  def overall_status
    publisher_ok = @publisher_service&.running? && @publisher_thread&.alive?
    consumer_ok = @consumer_service&.running? && @consumer_thread&.alive?
    
    if publisher_ok && consumer_ok
      'healthy'
    elsif publisher_ok || consumer_ok
      'degraded'
    else
      'unhealthy'
    end
  end
end
