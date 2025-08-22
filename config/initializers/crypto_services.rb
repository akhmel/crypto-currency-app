# Initialize and start cryptocurrency data services
Rails.application.config.after_initialize do
  begin
    # Initialize the service manager
    service_manager = CryptoDataServiceManager.instance
    service_manager.initialize_services
    
    # Start all services in a background thread to avoid blocking the main thread
    Thread.new do
      begin
        service_manager.start_all_services
      rescue => e
        Rails.logger.error "Failed to start crypto data services: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
    
    Rails.logger.info "Crypto data services initialization completed"
    
  rescue => e
    Rails.logger.error "Failed to initialize crypto data services: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end

# Graceful shutdown of services
at_exit do
  begin
    if defined?(CryptoDataServiceManager)
      service_manager = CryptoDataServiceManager.instance
      service_manager.stop_all_services
      Rails.logger.info "Crypto data services stopped gracefully"
    end
  rescue => e
    Rails.logger.error "Error stopping crypto data services: #{e.message}"
  end
end
