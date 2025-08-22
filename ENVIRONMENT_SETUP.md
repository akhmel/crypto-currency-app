# 🌍 Environment Setup Guide

This guide explains how to configure environment variables and database credentials for the Crypto Currency App.

## 🚀 Quick Setup

### Option 1: Automated Setup (Recommended)

Run the setup script to automatically create your `.env` file:

```bash
./setup_env.sh
```

This script will:
- Create a `.env` file with default values
- Check if required services (PostgreSQL, Redis, Kafka) are running
- Provide next steps for configuration

### Option 2: Manual Setup

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit the `.env` file with your actual credentials**

## 📋 Environment Variables

### Database Configuration

```bash
# PostgreSQL Database
POSTGRES_USER=crypto_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
```

**To create the database user:**
```bash
sudo -u postgres psql
CREATE USER crypto_user WITH PASSWORD 'your_secure_password';
CREATE DATABASE crypto_currency_app_development OWNER crypto_user;
CREATE DATABASE crypto_currency_app_test OWNER crypto_user;
GRANT ALL PRIVILEGES ON DATABASE crypto_currency_app_development TO crypto_user;
GRANT ALL PRIVILEGES ON DATABASE crypto_currency_app_test TO crypto_user;
\q
```

### Mailgun Configuration (Email Notifications)

```bash
# Get these from your Mailgun dashboard
MAILGUN_API_KEY=key-your_actual_api_key_here
MAILGUN_DOMAIN=your_verified_domain.com
MAILGUN_FROM_EMAIL=noreply@your_domain.com
```

**To get Mailgun credentials:**
1. Sign up at [Mailgun](https://www.mailgun.com/)
2. Verify your domain or use the sandbox domain
3. Get your API key from the dashboard

### Redis Configuration

```bash
# Redis for ActionCable and caching
REDIS_URL=redis://localhost:6379/0
```

**To install Redis:**
```bash
# macOS
brew install redis
brew services start redis

# Ubuntu/Debian
sudo apt install redis-server
sudo systemctl start redis
sudo systemctl enable redis
```

### Kafka Configuration

```bash
# Kafka for real-time data streaming
KAFKA_BROKERS=localhost:9092
KAFKA_TOPIC=ALL
```

**To start Kafka (using Docker):**
```bash
docker-compose up -d kafka
```

## 🔐 Security Best Practices

### 1. Never Commit Credentials

The following files are already in `.gitignore`:
- `.env`
- `.env.*`
- `config/application.yml`
- `config/secrets.yml`

### 2. Use Strong Passwords

- Database passwords should be at least 12 characters
- Include uppercase, lowercase, numbers, and special characters
- Consider using a password manager

### 3. Environment-Specific Files

Create different `.env` files for different environments:
```bash
.env.development    # Development environment
.env.test          # Test environment
.env.production    # Production environment (never commit)
```

## 🛠️ Configuration Management

### Using Figaro

The app includes the `figaro` gem for configuration management. You can access environment variables in your code:

```ruby
# In any Ruby file
Figaro.env.POSTGRES_USER
Figaro.env.MAILGUN_API_KEY
```

### Using dotenv-rails

The `dotenv-rails` gem automatically loads `.env` files in development and test environments.

## 🔍 Troubleshooting

### Common Issues

1. **"Database connection failed"**
   - Check if PostgreSQL is running
   - Verify credentials in `.env`
   - Ensure database exists

2. **"Mailgun API key invalid"**
   - Verify your API key in Mailgun dashboard
   - Check domain verification status
   - Ensure proper environment variables

3. **"Redis connection failed"**
   - Check if Redis is running
   - Verify Redis URL format
   - Check Redis port (default: 6379)

4. **"Kafka connection failed"**
   - Check if Kafka is running
   - Verify broker addresses
   - Check network connectivity

### Debug Commands

```bash
# Check PostgreSQL status
pg_isready -h localhost -p 5432

# Check Redis status
redis-cli ping

# Check Kafka status
nc -z localhost 9092

# Check environment variables
rails runner "puts ENV['POSTGRES_USER']"
```

## 📚 Next Steps

After setting up your environment:

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Create databases:**
   ```bash
   rails db:create
   ```

3. **Run migrations:**
   ```bash
   rails db:migrate
   ```

4. **Start the server:**
   ```bash
   rails server
   ```

5. **Test the API:**
   ```bash
   # Test database connection
   curl http://localhost:3000/api/v1/user_alerts
   
   # Test email notifications (if configured)
   curl -X POST http://localhost:3000/api/v1/user_notification_channels/1/test
   ```

## 🔄 Updating Configuration

To update environment variables:

1. **Edit the `.env` file**
2. **Restart your Rails server**
3. **Test the changes**

## 📖 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Mailgun API Documentation](https://documentation.mailgun.com/)
- [Rails Environment Configuration](https://guides.rubyonrails.org/configuring.html)
