require 'rails_helper'

RSpec.describe Api::V1::UserAlertsController, type: :request do
  let(:valid_attributes) do
    {
      symbol: 'BTCUSDT',
      target_price: 50000.0,
      alert_type: 'above',
      enabled: true,
      user_id: 1,
      notification_channel_id: 1
    }
  end

  let(:invalid_attributes) do
    {
      symbol: '',
      target_price: -100,
      alert_type: 'invalid_type',
      enabled: nil
    }
  end

  let(:user_alert) { UserAlert.create!(valid_attributes) }

  describe 'GET /api/v1/user_alerts' do
    before do
      create_list(:user_alert, 3)
    end

    it 'returns a list of user alerts' do
      get '/api/v1/user_alerts'
      
      expect(response).to have_http_status(:ok)
      expect(json_response['status']).to eq('success')
      expect(json_response['data']).to be_an(Array)
      expect(json_response['data'].length).to eq(3)
      expect(json_response['message']).to eq('User alerts retrieved successfully')
    end

    it 'returns empty array when no alerts exist' do
      UserAlert.destroy_all
      
      get '/api/v1/user_alerts'
      
      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to eq([])
    end
  end

  describe 'GET /api/v1/user_alerts/:id' do
    context 'when alert exists' do
      it 'returns the user alert' do
        get "/api/v1/user_alerts/#{user_alert.id}"
        
        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['id']).to eq(user_alert.id)
        expect(json_response['data']['symbol']).to eq('BTCUSDT')
        expect(json_response['message']).to eq('User alert retrieved successfully')
      end
    end

    context 'when alert does not exist' do
      it 'returns not found error' do
        get '/api/v1/user_alerts/99999'
        
        expect(response).to have_http_status(:not_found)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('User alert not found')
      end
    end
  end

  describe 'POST /api/v1/user_alerts' do
    context 'with valid attributes' do
      it 'creates a new user alert' do
        expect {
          post '/api/v1/user_alerts', params: { user_alert: valid_attributes }
        }.to change(UserAlert, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['symbol']).to eq('BTCUSDT')
        expect(json_response['data']['target_price']).to eq('50000.0')
        expect(json_response['data']['alert_type']).to eq('above')
        expect(json_response['message']).to eq('User alert created successfully')
      end

      it 'normalizes symbol to uppercase' do
        post '/api/v1/user_alerts', params: { 
          user_alert: valid_attributes.merge(symbol: 'btcusdt') 
        }

        expect(response).to have_http_status(:created)
        expect(json_response['data']['symbol']).to eq('BTCUSDT')
      end
    end

    context 'with invalid attributes' do
      it 'returns validation errors' do
        post '/api/v1/user_alerts', params: { user_alert: invalid_attributes }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['status']).to eq('error')
        expect(json_response['errors']).to include("Symbol can't be blank")
        expect(json_response['errors']).to include('Target price must be greater than 0')
        expect(json_response['errors']).to include('Alert type is not included in the list')
        expect(json_response['message']).to eq('Failed to create user alert')
      end

      it 'validates symbol length' do
        post '/api/v1/user_alerts', params: { 
          user_alert: valid_attributes.merge(symbol: 'A' * 21) 
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Symbol is too long (maximum is 20 characters)')
      end

      it 'validates alert type inclusion' do
        post '/api/v1/user_alerts', params: { 
          user_alert: valid_attributes.merge(alert_type: 'invalid') 
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Alert type is not included in the list')
      end
    end
  end

  describe 'PUT /api/v1/user_alerts/:id' do
    context 'with valid attributes' do
      it 'updates the user alert' do
        put "/api/v1/user_alerts/#{user_alert.id}", params: { 
          user_alert: { target_price: 60000.0, alert_type: 'below' } 
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['target_price']).to eq('60000.0')
        expect(json_response['data']['alert_type']).to eq('below')
        expect(json_response['message']).to eq('User alert updated successfully')
      end
    end

    context 'with invalid attributes' do
      it 'returns validation errors' do
        put "/api/v1/user_alerts/#{user_alert.id}", params: { 
          user_alert: { target_price: -100 } 
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['status']).to eq('error')
        expect(json_response['errors']).to include('Target price must be greater than 0')
      end
    end

    context 'when alert does not exist' do
      it 'returns not found error' do
        put '/api/v1/user_alerts/99999', params: { 
          user_alert: { target_price: 60000.0 } 
        }

        expect(response).to have_http_status(:not_found)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('User alert not found')
      end
    end
  end

  describe 'DELETE /api/v1/user_alerts/:id' do
    it 'deletes the user alert' do
      alert_to_delete = user_alert
      
      expect {
        delete "/api/v1/user_alerts/#{alert_to_delete.id}"
      }.to change(UserAlert, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_response['status']).to eq('success')
      expect(json_response['message']).to eq('User alert deleted successfully')
    end

    context 'when alert does not exist' do
      it 'returns not found error' do
        delete '/api/v1/user_alerts/99999'

        expect(response).to have_http_status(:not_found)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('User alert not found')
      end
    end
  end

  describe 'PATCH /api/v1/user_alerts/:id/toggle' do
    it 'toggles the enabled status' do
      expect(user_alert.enabled).to be true

      patch "/api/v1/user_alerts/#{user_alert.id}/toggle"

      expect(response).to have_http_status(:ok)
      expect(json_response['status']).to eq('success')
      expect(json_response['data']['enabled']).to be false
      expect(json_response['message']).to eq('User alert disabled successfully')

      patch "/api/v1/user_alerts/#{user_alert.id}/toggle"

      expect(json_response['data']['enabled']).to be true
      expect(json_response['message']).to eq('User alert enabled successfully')
    end

    context 'when alert does not exist' do
      it 'returns not found error' do
        patch '/api/v1/user_alerts/99999/toggle'

        expect(response).to have_http_status(:not_found)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('User alert not found')
      end
    end
  end

  describe 'GET /api/v1/user_alerts/check_triggers' do
    let!(:alert_above) { UserAlert.create!(symbol: 'BTCUSDT', target_price: 50000, alert_type: 'above', enabled: true) }
    let!(:alert_below) { UserAlert.create!(symbol: 'ETHUSDT', target_price: 3000, alert_type: 'below', enabled: true) }
    let!(:disabled_alert) { UserAlert.create!(symbol: 'ADAUSDT', target_price: 1.0, alert_type: 'above', enabled: false) }

    it 'returns triggered alerts for current prices' do
      current_prices = { 'BTCUSDT' => 55000, 'ETHUSDT' => 2500, 'ADAUSDT' => 1.5 }

      get '/api/v1/user_alerts/check_triggers', params: { current_prices: current_prices }

      expect(response).to have_http_status(:ok)
      expect(json_response['status']).to eq('success')
      expect(json_response['data']).to be_an(Array)
      expect(json_response['data'].length).to eq(2)
      expect(json_response['message']).to eq('Found 2 triggered alerts')

      # Check BTC alert (above 50000, current 55000)
      btc_alert = json_response['data'].find { |a| a['symbol'] == 'BTCUSDT' }
      expect(btc_alert['alert_type']).to eq('above')
      expect(btc_alert['current_price']).to eq(55000)

      # Check ETH alert (below 3000, current 2500)
      eth_alert = json_response['data'].find { |a| a['symbol'] == 'ETHUSDT' }
      expect(eth_alert['alert_type']).to eq('below')
      expect(eth_alert['current_price']).to eq(2500)
    end

    it 'returns empty array when no alerts are triggered' do
      current_prices = { 'BTCUSDT' => 45000, 'ETHUSDT' => 3500 }

      get '/api/v1/user_alerts/check_triggers', params: { current_prices: current_prices }

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to eq([])
      expect(json_response['message']).to eq('Found 0 triggered alerts')
    end

    it 'ignores disabled alerts' do
      current_prices = { 'ADAUSDT' => 2.0 }

      get '/api/v1/user_alerts/check_triggers', params: { current_prices: current_prices }

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to eq([])
    end

    it 'handles missing current prices gracefully' do
      get '/api/v1/user_alerts/check_triggers'

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to eq([])
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
