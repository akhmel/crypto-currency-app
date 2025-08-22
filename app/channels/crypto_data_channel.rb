class CryptoDataChannel < ApplicationCable::Channel
  def subscribed
    stream_from "crypto_data_channel"
    
    # Add client to the consumer service
    KafkaConsumerService.instance.add_client(connection.connection_identifier)
    
    # Send initial data to the client
    send_initial_data
  end

  def unsubscribed
    # Remove client from the consumer service
    KafkaConsumerService.instance.remove_client(connection.connection_identifier)
  end

  def request_latest_data(data)
    symbol = data['symbol']
    
    if symbol
      # Send latest data for specific symbol
      latest_data = KafkaConsumerService.instance.get_latest_data(symbol)
      if latest_data
        transmit({
          type: 'latest_data',
          symbol: symbol,
          data: latest_data,
          timestamp: Time.now.to_i * 1000
        })
      end
    else
      # Send all latest data
      all_data = KafkaConsumerService.instance.get_all_latest
      transmit({
        type: 'all_latest_data',
        data: all_data,
        timestamp: Time.now.to_i * 1000
      })
    end
  end

  def request_historical_data(data)
    # This can be implemented later to fetch historical data
    # For now, just acknowledge the request
    transmit({
      type: 'historical_data_request',
      message: 'Historical data feature coming soon',
      timestamp: Time.now.to_i * 1000
    })
  end

  private

  def send_initial_data
    # Send all latest data when client first connects
    all_data = KafkaConsumerService.instance.get_all_latest
    
    transmit({
      type: 'initial_data',
      data: all_data,
      timestamp: Time.now.to_i * 1000,
      message: 'Connected to real-time cryptocurrency data stream'
    })
  end
end
