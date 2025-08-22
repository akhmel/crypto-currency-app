#!/bin/bash

# Crypto Currency App Environment Setup Script
echo "🚀 Setting up Crypto Currency App environment..."

# Check if .env file exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists. Backing up to .env.backup"
    cp .env .env.backup
fi

# Create .env file
echo "📝 Creating .env file..."
cat > .env << 'EOF'
# Database Configuration
POSTGRES_USER=crypto_user
POSTGRES_PASSWORD=crypto_password_123
POSTGRES_HOST=localhost
POSTGRES_PORT=5432

# Mailgun Configuration (for email notifications)
MAILGUN_API_KEY=key-your_mailgun_api_key_here
MAILGUN_DOMAIN=your_domain.com
MAILGUN_FROM_EMAIL=noreply@your_domain.com

# Redis Configuration (for ActionCable and caching)
REDIS_URL=redis://localhost:6379/0

# Kafka Configuration
KAFKA_BROKERS=localhost:9092
KAFKA_TOPIC=ALL

# Rails Environment
RAILS_ENV=development
RAILS_MAX_THREADS=5

# Application Configuration
APP_HOST=localhost
APP_PORT=3000
EOF

echo "✅ .env file created successfully!"

# Check if PostgreSQL is running
echo "🔍 Checking PostgreSQL status..."
if pg_isready -q; then
    echo "✅ PostgreSQL is running"
else
    echo "❌ PostgreSQL is not running. Please start it first:"
    echo "   brew services start postgresql  # macOS"
    echo "   sudo systemctl start postgresql # Linux"
fi

# Check if Redis is running
echo "🔍 Checking Redis status..."
if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis is running"
else
    echo "❌ Redis is not running. Please start it first:"
    echo "   brew services start redis       # macOS"
    echo "   sudo systemctl start redis      # Linux"
fi

# Check if Kafka is running
echo "🔍 Checking Kafka status..."
if nc -z localhost 9092 2>/dev/null; then
    echo "✅ Kafka is running on port 9092"
else
    echo "❌ Kafka is not running. Please start it first:"
    echo "   docker-compose up -d kafka     # If using Docker"
fi

echo ""
echo "🎯 Next steps:"
echo "1. Edit .env file with your actual credentials"
echo "2. Install dependencies: bundle install"
echo "3. Create database: rails db:create"
echo "4. Run migrations: rails db:migrate"
echo "5. Start the server: rails server"
echo ""
echo "📚 For detailed setup instructions, see API_SETUP.md"
