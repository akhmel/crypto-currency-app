# 🚀 Kafka Setup Guide for Crypto Currency App

This guide explains how to set up and run the Kafka-based real-time cryptocurrency data streaming system.

## 🏗️ Architecture Overview

```
Binance WebSocket → Kafka Publisher → Kafka Topic 'ALL' → Kafka Consumer → ActionCable → React Frontend
```

### Components:
1. **KafkaPublisherService**: Connects to Binance WebSocket and publishes data to Kafka
2. **KafkaConsumerService**: Consumes from Kafka and broadcasts to connected clients
3. **CryptoDataChannel**: ActionCable channel for real-time communication
4. **useCryptoDataStream**: React hook for consuming real-time data

## 📋 Prerequisites

### Required Services:
- **Kafka** (with Zookeeper)
- **Redis** (for ActionCable and caching)
- **PostgreSQL** (Rails database)

### System Requirements:
- Ruby 3.0+
- Node.js 16+
- Docker (recommended for local development)

## 🐳 Quick Start with Docker

### 1. Start Kafka and Redis with Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    hostname: zookeeper
    container_name: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    volumes:
      - zookeeper-data:/var/lib/zookeeper/data
      - zookeeper-logs:/var/lib/zookeeper/log

  kafka:
    image: confluentinc/cp-kafka:7.4.0
    hostname: kafka
    container_name: kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
      - "9101:9101"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_JMX_PORT: 9101
      KAFKA_JMX_HOSTNAME: localhost
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: 'true'
      KAFKA_DELETE_TOPIC_ENABLE: 'true'
    volumes:
      - kafka-data:/var/lib/kafka/data

  redis:
    image: redis:7-alpine
    hostname: redis
    container_name: redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data

volumes:
  zookeeper-data:
  zookeeper-logs:
  kafka-data:
  redis-data:
```

Start the services:

```bash
docker-compose up -d
```

### 2. Verify Services are Running

```bash
# Check Kafka
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list

# Check Redis
docker exec redis redis-cli ping
```

## 🔧 Rails Application Setup

### 1. Install Dependencies

```bash
bundle install
```

### 2. Environment Variables

Create `.env` file:

```bash
# Kafka Configuration
KAFKA_BROKERS=localhost:9092

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# Binance API (optional, for additional features)
BINANCE_API_KEY=your_api_key
BINANCE_SECRET_KEY=your_secret_key
```

### 3. Database Setup

```bash
rails db:create
rails db:migrate
```

### 4. Start the Rails Server

```bash
rails server
```

## 🚀 Starting the Services

### Automatic Startup
The services will start automatically when Rails initializes (see `config/initializers/crypto_services.rb`).

### Manual Control
You can also control the services manually:

```ruby
# In Rails console
service_manager = CryptoDataServiceManager.instance

# Check status
service_manager.services_status

# Start services
service_manager.start_all_services

# Stop services
service_manager.stop_all_services

# Restart services
service_manager.restart_all_services
```

## 📊 Monitoring and Debugging

### 1. Service Health Check

```ruby
# In Rails console
service_manager = CryptoDataServiceManager.instance
service_manager.health_check
```

### 2. Kafka Topic Monitoring

```bash
# List topics
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list

# Monitor messages in real-time
docker exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic ALL --from-beginning

# Check topic details
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic ALL
```

### 3. Redis Monitoring

```bash
# Connect to Redis CLI
docker exec -it redis redis-cli

# Monitor Redis operations
MONITOR

# Check keys
KEYS crypto:*
```

### 4. Rails Logs

```bash
# View Rails logs
tail -f log/development.log

# Filter for crypto services
tail -f log/development.log | grep -E "(Kafka|Crypto|Binance)"
```

## 🔍 Troubleshooting

### Common Issues:

#### 1. Kafka Connection Failed
```
Error: Failed to connect to Kafka: Connection refused
```

**Solution:**
- Ensure Kafka is running: `docker ps | grep kafka`
- Check Kafka logs: `docker logs kafka`
- Verify port 9092 is accessible

#### 2. Redis Connection Failed
```
Error: Failed to connect to Redis: Connection refused
```

**Solution:**
- Ensure Redis is running: `docker ps | grep redis`
- Check Redis logs: `docker logs redis`
- Verify port 6379 is accessible

#### 3. Binance WebSocket Connection Failed
```
Error: WebSocket connection failed
```

**Solution:**
- Check internet connectivity
- Verify Binance API status
- Check firewall settings

#### 4. ActionCable Connection Issues
```
Error: Connection rejected by server
```

**Solution:**
- Ensure Redis is running for ActionCable
- Check ActionCable configuration
- Verify channel permissions

### Debug Commands:

```bash
# Check all service statuses
docker ps

# View service logs
docker logs kafka
docker logs redis
docker logs zookeeper

# Check network connectivity
telnet localhost 9092  # Kafka
telnet localhost 6379  # Redis
telnet localhost 2181  # Zookeeper
```

## 📈 Performance Tuning

### Kafka Configuration:
- Adjust `num_partitions` in `KafkaPublisherService` based on your needs
- Monitor consumer lag and adjust `session_timeout` and `heartbeat_interval`

### Redis Configuration:
- Adjust TTL for cached data (currently 5 minutes)
- Monitor memory usage and adjust Redis configuration

### WebSocket Configuration:
- Adjust reconnection intervals
- Monitor connection stability

## 🔒 Security Considerations

### Production Deployment:
1. **Kafka Security:**
   - Enable SSL/TLS encryption
   - Configure SASL authentication
   - Use secure ports

2. **Redis Security:**
   - Enable Redis authentication
   - Use SSL connections
   - Restrict network access

3. **Binance API:**
   - Use API keys with appropriate permissions
   - Monitor API usage limits
   - Implement rate limiting

## 📚 Additional Resources

- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Redis Documentation](https://redis.io/documentation)
- [ActionCable Guide](https://guides.rubyonrails.org/action_cable_overview.html)
- [Binance WebSocket API](https://binance-docs.github.io/apidocs/spot/en/#websocket-market-streams)

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Rails logs for detailed error messages
3. Verify all services are running correctly
4. Check network connectivity and firewall settings
