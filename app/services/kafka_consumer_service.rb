require 'kafka'
require 'json'
require 'logger'
require 'concurrent'
require 'redis'

class KafkaConsumerService
  include Singleton

  def initialize
    @logger = Logger.new(STDOUT)
    @kafka = nil
    @consumer = nil
    @running = false
    @redis = nil
    @connected_clients = Concurrent::Array.new
    
    setup_kafka
    setup_redis
  end

  def start
    @logger.info "Starting Kafka Consumer Service...1"
    @logger.info "Service instance: #{self.class.name} (ID: #{object_id})"
    return if @running
    
    @logger.info "Starting Kafka Consumer Service...2"
    @running = true
    
    begin
      start_consuming
    rescue => e
      @logger.error "Error in Kafka Consumer Service: #{e.message}"
      @logger.error e.backtrace.join("\n")
      stop
    end
  end

  def stop
    @logger.info "Stopping Kafka Consumer Service..."
    @running = false
    
    if @consumer
      @consumer.stop
      @consumer = nil
    end
  end

  def running?
    @running
  end

  def add_client(client_id)
    @connected_clients << client_id
    @logger.info "Client connected: #{client_id} (Total: #{@connected_clients.size})"
  end

  def remove_client(client_id)
    @connected_clients.delete(client_id)
    @logger.info "Client disconnected: #{client_id} (Total: #{@connected_clients.size})"
  end

  def broadcast_to_clients(data)
    puts "Broadcasting to clients...------------------- #{data}"
    return if @connected_clients.empty?
    
    # Store latest data in Redis for new connections
    store_latest_data(data)
    
    # Broadcast to all connected clients via ActionCable
    broadcast_via_action_cable(data)
  end

  private

  def setup_kafka
    begin
      @kafka = Kafka.new(
        seed_brokers: kafka_brokers,
        client_id: 'crypto-consumer',
        logger: @logger
      )
      
      @logger.info "Consumer Service: Kafka connection established successfully"
    rescue => e
      @logger.error "Consumer Service: Failed to connect to Kafka: #{e.message}"
      raise e
    end
  end

  def setup_redis
    begin
      @redis = Redis.new(
        url: redis_url,
        timeout: 1
      )
      @redis.ping
      @logger.info "Consumer Service: Redis connection established successfully"
    rescue => e
      @logger.error "Consumer Service: Failed to connect to Redis: #{e.message}"
      @logger.warn "Continuing without Redis caching..."
      @redis = nil
    end
  end

  def kafka_brokers
    ENV['KAFKA_BROKERS'] || 'localhost:9092'
  end

  def redis_url
    ENV['REDIS_URL'] || 'redis://localhost:6379/0'
  end

  def start_consuming
    @logger.info "Starting to consume from Kafka topic 'ALL'..."
    
    @consumer = @kafka.consumer(
      group_id: 'crypto-consumer-group',
      session_timeout: 30,
      heartbeat_interval: 10
    )
    
    @consumer.subscribe('ALL', start_from_beginning: false)
    
    @consumer.each_message do |message|
      break unless @running
      
      begin
        data = JSON.parse(message.value)
        @logger.debug "Received message: #{data['symbol']} - $#{data['price']}"
        
        # Process and broadcast the data
        process_and_broadcast(data)
        
      rescue JSON::ParserError => e
        @logger.warn "Failed to parse Kafka message: #{e.message}"
      rescue => e
        @logger.error "Error processing Kafka message: #{e.message}"
      end
    end
  end

  def process_and_broadcast(data)
    # Transform data to match frontend expectations
    transformed_data = transform_kafka_data(data)
    
    # Broadcast to connected clients
    broadcast_to_clients(transformed_data)
  end

  def transform_kafka_data(kafka_data)
    {
      symbol: kafka_data['symbol'],
      name: kafka_data['name'],
      price: kafka_data['price'],
      priceChange: kafka_data['price_change'],
      priceChangePercent: kafka_data['price_change_percent'],
      highPrice: kafka_data['high_price'],
      lowPrice: kafka_data['low_price'],
      volume: kafka_data['volume'],
      quoteVolume: kafka_data['quote_volume'],
      openPrice: kafka_data['open_price'],
      weightedAvgPrice: kafka_data['weighted_avg_price'],
      prevClosePrice: kafka_data['prev_close_price'],
      bidPrice: kafka_data['bid_price'],
      askPrice: kafka_data['ask_price'],
      timestamp: kafka_data['timestamp'],
      eventTime: kafka_data['event_time'],
      eventType: kafka_data['event_type']
    }
  end

  def store_latest_data(data)
    return unless @redis
    
    begin
      # Store latest data for each symbol
      key = "crypto:latest:#{data[:symbol]}"
      @redis.setex(key, 300, data.to_json) # Expire in 5 minutes
      
      # Store aggregated data for all symbols
      @redis.setex('crypto:latest:all', 300, get_all_latest_data.to_json)
    rescue => e
      @logger.warn "Failed to store data in Redis: #{e.message}"
    end
  end

  def get_all_latest_data
    return [] unless @redis
    
    begin
      # Get all latest data from Redis
      keys = @redis.keys('crypto:latest:*')
      keys.reject { |k| k == 'crypto:latest:all' }.map do |key|
        data = @redis.get(key)
        JSON.parse(data) if data
      end.compact
    rescue => e
      @logger.warn "Failed to get latest data from Redis: #{e.message}"
      []
    end
  end

  def broadcast_via_action_cable(data)
    # This will be called by ActionCable when broadcasting
    # The actual broadcasting happens in the CryptoDataChannel
    ActionCable.server.broadcast(
      'crypto_data_channel',
      {
        type: 'price_update',
        data: data,
        timestamp: Time.now.to_i * 1000
      }
    )
  end

  # Public method to get latest data for a specific symbol
  def get_latest_data(symbol)
    return nil unless @redis
    
    begin
      data = @redis.get("crypto:latest:#{symbol}")
      data ? JSON.parse(data) : nil
    rescue => e
      @logger.warn "Failed to get latest data for #{symbol}: #{e.message}"
      nil
    end
  end

  # Public method to get all latest data
  def get_all_latest
    get_all_latest_data
  end

  # Method to check service health
  def health_check
    {
      running: @running,
      kafka_connected: !@kafka.nil?,
      redis_connected: !@redis.nil?,
      connected_clients: @connected_clients.size,
      timestamp: Time.now.to_i
    }
  end
end
