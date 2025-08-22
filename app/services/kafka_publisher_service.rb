require 'kafka'
require 'websocket-client-simple'
require 'json'
require 'logger'

class KafkaPublisherService
  include Singleton

  def initialize
    @logger = Logger.new(STDOUT)
    @kafka = nil
    @websocket = nil
    @running = false
    @symbols = [
      'btcusdt', 'ethusdt', 'adausdt', 'solusdt', 'dotusdt',
      'linkusdt', 'ltcusdt', 'bchusdt', 'xrpusdt', 'bnbusdt'
    ]
    
    setup_kafka
  end

  def start
    return if @running
    
    @logger.info "Starting Kafka Publisher Service..."
    @logger.info "Service instance: #{self.class.name} (ID: #{object_id})"
    @logger.info "Available methods: #{methods.grep(/handle_message|connect_websocket/)}"
    
    @running = true
    
    begin
      @logger.info "Initializing WebSocket connection..."
      connect_websocket
      @logger.info "Starting publishing loop..."
      start_publishing
    rescue => e
      @logger.error "Error in Kafka Publisher Service: #{e.message}"
      @logger.error e.backtrace.join("\n")
      stop
    end
  end

  def stop
    @logger.info "Stopping Kafka Publisher Service..."
    @running = false
    
    if @websocket
      @websocket.close
      @websocket = nil
    end
  end

  def running?
    @running
  end

  def handle_message(msg)
    return unless @running
    
    begin
      # Parse the message data
      data = JSON.parse(msg.data)
      
      # Transform the data to our standard format
      transformed_data = transform_binance_data(data)
      
      # Publish to Kafka
      publish_to_kafka(transformed_data)
      
    rescue JSON::ParserError => e
      @logger.warn "Failed to parse WebSocket message: #{e.message}"
    rescue => e
      @logger.error "Error handling WebSocket message: #{e.message}"
      @logger.error e.backtrace.join("\n") if e.respond_to?(:backtrace)
    end
  end

  private

  def setup_kafka
    begin
      @kafka = Kafka.new(
        seed_brokers: kafka_brokers,
        client_id: 'crypto-publisher',
        logger: @logger
      )
      
      # Check if the topic exists
      if @kafka.topics.include?('ALL')
        @logger.info "Publisher Service: Topic 'ALL' already exists"
      else
        @kafka.create_topic('ALL', num_partitions: 3, replication_factor: 1)
        @logger.info "Publisher Service: Topic 'ALL' created"
      end

      @logger.info "Publisher Service: Kafka connection established successfully"
    rescue => e
      @logger.error "Publisher Service: Failed to connect to Kafka: #{e.message}"
      raise e
    end
  end

  def kafka_brokers
    ENV['KAFKA_BROKERS'] || 'localhost:9092'
  end

  def connect_websocket
    # Create a single WebSocket connection for all symbols
    @logger.info "Connecting to Binance WebSocket"

    # Binance WebSocket format for multiple symbols: wss://stream.binance.com:9443/ws/btcusdt@ticker/ethusdt@ticker
    # Each symbol needs to be lowercase and separated by /
    stream_url = "wss://stream.binance.com:9443/ws/#{@symbols.map { |s| "#{s}@ticker" }.join('/')}"
    
    @logger.info "Connecting to Binance WebSocket: #{stream_url}"
    @logger.info "WebSocket::Client::Simple version: #{WebSocket::Client::Simple::VERSION rescue 'Unknown'}"
    
    begin
      @websocket = WebSocket::Client::Simple.connect stream_url
      #@logger.info "WebSocket client created: #{@websocket.class}"
      puts "WebSocket client created: #{@websocket.class}"
      
      # Store reference to self for use in event handlers
      service_instance = self
      
      # Set up event handlers using lambda functions to ensure proper binding
      @websocket.on :message do |msg|
        #@logger.debug "Received WebSocket message: #{msg.data}"
        puts "Received WebSocket message: #{msg.data}"
        service_instance.handle_message(msg)
      end
      
      @websocket.on :open do
        #@logger.info "WebSocket connection opened successfully"
        puts "WebSocket connection opened successfully"
      end
      
      @websocket.on :error do |e|
        #@logger.error "WebSocket error: #{e.message}"
        puts "WebSocket error: #{e.message}"
        if e.respond_to?(:backtrace)
          #@logger.error e.backtrace.join("\n")
          puts e.backtrace.join("\n")
        end
      end
      
      @websocket.on :close do |e|
        @logger.warn "WebSocket connection closed: #{e.code} #{e.reason}"
        # Attempt to reconnect if service is still running
        if service_instance.instance_variable_get(:@running)
          @logger.info "Attempting to reconnect in 5 seconds..."
          sleep 5
          service_instance.connect_websocket
        end
      end
      
      # Additional event handlers for debugging
      @websocket.on :ping do |data|
        @logger.debug "Received ping: #{data}"
      end
      
      @websocket.on :pong do |data|
        @logger.debug "Received pong: #{data}"
      end
      
      @logger.info "WebSocket event handlers configured successfully"
      
    rescue => e
      @logger.error "Failed to create WebSocket connection: #{e.message}"
      @logger.error e.backtrace.join("\n")
      
      # Attempt to reconnect if service is still running
      if @running
        @logger.info "Attempting to reconnect in 10 seconds..."
        sleep 10
        connect_websocket
      end
    end
  end

  def transform_binance_data(binance_data)
    {
      symbol: binance_data['s'],
      name: get_crypto_name(binance_data['s']),
      price: binance_data['c'].to_f,
      price_change: binance_data['P'].to_f,
      price_change_percent: binance_data['P'].to_f,
      high_price: binance_data['h'].to_f,
      low_price: binance_data['l'].to_f,
      volume: binance_data['v'].to_f,
      quote_volume: binance_data['q'].to_f,
      open_price: binance_data['o'].to_f,
      weighted_avg_price: binance_data['w'].to_f,
      prev_close_price: binance_data['p'].to_f,
      bid_price: binance_data['b'].to_f,
      ask_price: binance_data['a'].to_f,
      timestamp: Time.now.to_i * 1000,
      event_time: binance_data['E'],
      event_type: '24hrTicker'
    }
  end

  def get_crypto_name(symbol)
    names = {
      'BTCUSDT' => 'Bitcoin',
      'ETHUSDT' => 'Ethereum',
      'ADAUSDT' => 'Cardano',
      'SOLUSDT' => 'Solana',
      'DOTUSDT' => 'Polkadot',
      'LINKUSDT' => 'Chainlink',
      'LTCUSDT' => 'Litecoin',
      'BCHUSDT' => 'Bitcoin Cash',
      'XRPUSDT' => 'Ripple',
      'BNBUSDT' => 'Binance Coin'
    }
    names[symbol] || symbol
  end

  def publish_to_kafka(data)
    return unless @kafka
    
    begin
      # Publish to Kafka topic 'ALL'
      @kafka.deliver_message(
        data.to_json,
        topic: 'ALL',
        key: data[:symbol],
        partition_key: data[:symbol]
      )
      
      @logger.debug "Published to Kafka: #{data[:symbol]} - $#{data[:price]}"
    rescue => e
      @logger.error "Failed to publish to Kafka: #{e.message}"
    end
  end

  def start_publishing
    @logger.info "Kafka Publisher Service is now running..."
    
    # Keep the service running
    while @running
      sleep 1
    end
  end
end
