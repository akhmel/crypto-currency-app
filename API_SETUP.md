# Crypto Currency App API Setup Guide

This guide covers the setup and usage of the User Alerts and Notification Channels API system.

## 🗄️ Database Setup

### 1. Install PostgreSQL

**macOS (using Homebrew):**
```bash
brew install postgresql
brew services start postgresql
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 2. Create Database User

```bash
sudo -u postgres psql
CREATE USER crypto_user WITH PASSWORD 'your_password';
CREATE DATABASE crypto_currency_app_development OWNER crypto_user;
CREATE DATABASE crypto_currency_app_test OWNER crypto_user;
GRANT ALL PRIVILEGES ON DATABASE crypto_currency_app_development TO crypto_user;
GRANT ALL PRIVILEGES ON DATABASE crypto_currency_app_test TO crypto_user;
\q
```

### 3. Set Environment Variables

Create a `.env` file in your project root:

```bash
# Database Configuration
POSTGRES_USER=crypto_user
POSTGRES_PASSWORD=your_password
POSTGRES_HOST=localhost
POSTGRES_PORT=5432

# Mailgun Configuration (for email notifications)
MAILGUN_API_KEY=your_mailgun_api_key
MAILGUN_DOMAIN=your_domain.com
MAILGUN_FROM_EMAIL=noreply@your_domain.com
```

### 4. Run Database Migrations

```bash
# Install dependencies
bundle install

# Create and migrate databases
rails db:create
rails db:migrate

# Seed test data (optional)
rails db:seed
```

## 🚀 API Endpoints

### User Alerts API

#### Base URL: `/api/v1/user_alerts`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | List all user alerts |
| GET | `/:id` | Get specific user alert |
| POST | `/` | Create new user alert |
| PUT | `/:id` | Update user alert |
| DELETE | `/:id` | Delete user alert |
| PATCH | `/:id/toggle` | Toggle alert enabled status |
| GET | `/check_triggers` | Check which alerts are triggered |

#### Create Alert Example

```bash
curl -X POST http://localhost:3000/api/v1/user_alerts \
  -H "Content-Type: application/json" \
  -d '{
    "user_alert": {
      "symbol": "BTCUSDT",
      "target_price": 50000.0,
      "alert_type": "above",
      "enabled": true,
      "user_id": 1,
      "notification_channel_id": 1
    }
  }'
```

#### Check Triggers Example

```bash
curl -X GET "http://localhost:3000/api/v1/user_alerts/check_triggers?current_prices[BTCUSDT]=55000&current_prices[ETHUSDT]=2500"
```

### User Notification Channels API

#### Base URL: `/api/v1/user_notification_channels`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | List all notification channels |
| GET | `/:id` | Get specific notification channel |
| POST | `/` | Create new notification channel |
| PUT | `/:id` | Update notification channel |
| DELETE | `/:id` | Delete notification channel |
| PATCH | `/:id/toggle` | Toggle channel enabled status |
| POST | `/:id/test` | Test notification channel |

#### Create Browser Channel Example

```bash
curl -X POST http://localhost:3000/api/v1/user_notification_channels \
  -H "Content-Type: application/json" \
  -d '{
    "user_notification_channel": {
      "channel_type": "browser",
      "enabled": true,
      "user_id": 1,
      "preferences": "{\"sound\": true, \"duration\": 5000}"
    }
  }'
```

#### Create Email Channel Example

```bash
curl -X POST http://localhost:3000/api/v1/user_notification_channels \
  -H "Content-Type: application/json" \
  -d '{
    "user_notification_channel": {
      "channel_type": "email",
      "email_address": "user@example.com",
      "enabled": true,
      "user_id": 1,
      "preferences": "{\"html_format\": true, \"frequency\": \"immediate\"}"
    }
  }'
```

#### Test Email Channel Example

```bash
curl -X POST http://localhost:3000/api/v1/user_notification_channels/1/test
```

## 📧 Email Notifications Setup

### 1. Mailgun Account Setup

1. Sign up at [Mailgun](https://www.mailgun.com/)
2. Verify your domain or use the sandbox domain
3. Get your API key from the dashboard

### 2. Environment Variables

```bash
MAILGUN_API_KEY=key-your_api_key_here
MAILGUN_DOMAIN=your_domain.com
MAILGUN_FROM_EMAIL=noreply@your_domain.com
```

### 3. Test Email Sending

```bash
# Test the email channel
curl -X POST http://localhost:3000/api/v1/user_notification_channels/1/test
```

## 🧪 Testing

### Run RSpec Tests

```bash
# Run all tests
bundle exec rspec

# Run specific controller tests
bundle exec rspec spec/requests/api/v1/user_alerts_controller_spec.rb
bundle exec rspec spec/requests/api/v1/user_notification_channels_controller_spec.rb

# Run with coverage report
COVERAGE=true bundle exec rspec
```

### Test Data

The tests use FactoryBot factories located in `spec/factories/`:

- `spec/factories/user_alerts.rb` - User Alert factories
- `spec/factories/user_notification_channels.rb` - Notification Channel factories

## 🔧 Configuration

### Model Validations

#### UserAlert
- `symbol`: Required, max 20 characters, auto-uppercase
- `target_price`: Required, must be positive
- `alert_type`: Must be 'above' or 'below'
- `enabled`: Boolean, defaults to true

#### UserNotificationChannel
- `channel_type`: Must be 'browser' or 'email'
- `email_address`: Required for email channels, must be valid format
- `enabled`: Boolean, defaults to true
- `preferences`: JSON string for custom settings

### Scopes

#### UserAlert Scopes
- `enabled` - Only enabled alerts
- `by_symbol(symbol)` - Filter by cryptocurrency symbol
- `by_type(type)` - Filter by alert type
- `active` - Alerts created in last 30 days

#### UserNotificationChannel Scopes
- `enabled` - Only enabled channels
- `by_type(type)` - Filter by channel type
- `browser_channels` - Only browser channels
- `email_channels` - Only email channels
- `active` - Channels created in last 30 days

## 📊 Database Schema

### user_alerts Table
```sql
CREATE TABLE user_alerts (
  id SERIAL PRIMARY KEY,
  symbol VARCHAR(20) NOT NULL,
  target_price DECIMAL NOT NULL CHECK (target_price > 0),
  alert_type VARCHAR(10) NOT NULL CHECK (alert_type IN ('above', 'below')),
  enabled BOOLEAN DEFAULT true,
  user_id INTEGER,
  notification_channel_id INTEGER,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### user_notification_channels Table
```sql
CREATE TABLE user_notification_channels (
  id SERIAL PRIMARY KEY,
  channel_type VARCHAR(20) NOT NULL CHECK (channel_type IN ('browser', 'email')),
  email_address VARCHAR(255),
  enabled BOOLEAN DEFAULT true,
  user_id INTEGER,
  preferences TEXT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

## 🚨 Alert Triggering Logic

### Price Alert Conditions

- **Above Alert**: Triggers when `current_price >= target_price`
- **Below Alert**: Triggers when `current_price <= target_price`

### Example Usage

```ruby
# Check if alerts are triggered
current_prices = {
  'BTCUSDT' => 55000,
  'ETHUSDT' => 2500
}

response = HTTParty.get('http://localhost:3000/api/v1/user_alerts/check_triggers', 
  query: { current_prices: current_prices }
)

triggered_alerts = JSON.parse(response.body)['data']
```

## 🔄 Integration with Crypto Data System

The API system integrates with the existing Kafka-based crypto data streaming:

1. **Real-time Price Updates**: Kafka consumer receives price updates
2. **Alert Checking**: API checks for triggered alerts
3. **Notification Sending**: Sends notifications via configured channels
4. **Browser Notifications**: Frontend displays browser notifications
5. **Email Notifications**: Mailgun sends formatted email alerts

## 🛠️ Troubleshooting

### Common Issues

1. **Database Connection Error**
   - Check PostgreSQL is running
   - Verify environment variables
   - Check database user permissions

2. **Mailgun API Errors**
   - Verify API key is correct
   - Check domain verification status
   - Ensure proper environment variables

3. **Test Failures**
   - Run `rails db:test:prepare`
   - Check factory definitions
   - Verify model validations

### Logs

Check Rails logs for detailed error information:
```bash
tail -f log/development.log
```

## 📚 Additional Resources

- [Rails API Guide](https://guides.rubyonrails.org/api_app.html)
- [Mailgun API Documentation](https://documentation.mailgun.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [RSpec Rails Documentation](https://relishapp.com/rspec/rspec-rails)
