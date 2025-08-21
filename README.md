# 🚀 Crypto Currency Alert System

A React-based cryptocurrency price monitoring and alert system built with Rails backend support.

## Features

### 📊 Live Price Monitoring
- Real-time cryptocurrency prices from Binance API
- Price change indicators with color coding
- 24-hour high/low prices and volume data
- Auto-refresh functionality

### 🔔 Smart Price Alerts
- Set price alerts above or below target prices
- Enable/disable alerts as needed
- Visual alert management interface
- Alert history tracking

### 🎨 Modern UI/UX
- Dark/light theme toggle
- Responsive design for all devices
- Mantine UI components for consistency
- Smooth animations and transitions

## Components

### `PriceAlert.jsx`
Individual cryptocurrency price cards with alert functionality:
- Current price display
- 24h price change percentage
- Volume and high/low data
- Quick alert setup modal

### `PriceTicker.jsx`
Real-time price ticker with live updates:
- Scrollable list of all cryptocurrencies
- Visual price change indicators
- Last update timestamp
- Refresh button for manual updates

### `AlertManager.jsx`
Comprehensive alert management system:
- Add new price alerts
- Edit existing alerts
- Enable/disable alerts
- Delete alerts
- Alert status overview

### `binanceApi.js`
Service for Binance API integration:
- Fetch current prices
- Get 24h statistics
- Multiple symbol support
- Error handling and formatting

### `alertService.js`
Alert management service for Rails API:
- CRUD operations for alerts
- Data validation
- API endpoint configuration
- Error handling

## Setup Instructions

### Prerequisites
- Node.js (v16 or higher)
- Ruby on Rails (v7 or higher)
- Yarn or npm

### Frontend Setup
1. Install dependencies:
   ```bash
   yarn install
   ```

2. Start the development server:
   ```bash
   yarn dev
   ```

### Backend Setup (Future)
The system is designed to work with a Rails API backend. When you're ready to implement it:

1. Create API endpoints for alerts:
   - `GET /api/v1/alerts` - List all alerts
   - `POST /api/v1/alerts` - Create new alert
   - `PUT /api/v1/alerts/:id` - Update alert
   - `DELETE /api/v1/alerts/:id` - Delete alert
   - `PATCH /api/v1/alerts/:id/toggle` - Toggle alert status

2. Update the `alertService.js` base URL to match your Rails API

3. Implement authentication if needed

## API Integration

### Binance API
The system currently uses mock data but is ready for Binance API integration:

```javascript
// In loadCryptoData() function, replace mock data with:
const data = await binanceApi.getMultiplePrices()
setCryptoData(data)
```

### Rails API
The alert system is designed to work with a Rails backend:

```ruby
# Example Rails controller structure
class Api::V1::AlertsController < ApplicationController
  def index
    @alerts = current_user.alerts
    render json: @alerts
  end

  def create
    @alert = current_user.alerts.build(alert_params)
    if @alert.save
      render json: @alert, status: :created
    else
      render json: @alert.errors, status: :unprocessable_entity
    end
  end

  # ... other CRUD actions
end
```

## Data Structure

### Cryptocurrency Data
```javascript
{
  symbol: 'BTCUSDT',
  name: 'Bitcoin',
  price: 43250.50,
  priceChange: 1081.25,
  priceChangePercent: 2.56,
  highPrice: 44500.00,
  lowPrice: 42000.00,
  volume: 1234567.89,
  quoteVolume: 53456789012.34
}
```

### Alert Data
```javascript
{
  id: 1,
  symbol: 'BTCUSDT',
  targetPrice: 45000,
  type: 'above', // 'above' or 'below'
  enabled: true,
  createdAt: '2024-01-01T00:00:00Z'
}
```

## Customization

### Adding New Cryptocurrencies
Update the `supportedSymbols` array in `binanceApi.js`:

```javascript
this.supportedSymbols = [
  'BTCUSDT', 'ETHUSDT', 'ADAUSDT', 'SOLUSDT', 'DOTUSDT',
  'LINKUSDT', 'LTCUSDT', 'BCHUSDT', 'XRPUSDT', 'BNBUSDT',
  'NEWCOINUSDT' // Add your new coin here
]
```

### Styling
The system uses Mantine UI components. Customize the theme in `App.jsx`:

```javascript
const theme = createTheme({
  primaryColor: 'blue', // Change primary color
  fontFamily: 'Inter, sans-serif', // Change font
  // Add more theme customizations
})
```

## Future Enhancements

- WebSocket integration for real-time price updates
- Push notifications for triggered alerts
- Price chart integration
- Portfolio tracking
- Social features and sharing
- Mobile app development

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.
