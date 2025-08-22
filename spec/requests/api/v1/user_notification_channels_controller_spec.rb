require 'rails_helper'

RSpec.describe Api::V1::UserNotificationChannelsController, type: :request do
  let(:valid_browser_attributes) do
    {
      channel_type: 'browser',
      enabled: true,
      user_id: 1,
      preferences: { sound: true, duration: 5000 }.to_json
    }
  end

  let(:valid_email_attributes) do
    {
      channel_type: 'email',
      email_address: 'test@example.com',
      enabled: true,
      user_id: 1,
      preferences: { html_format: true, frequency: 'immediate' }.to_json
    }
  end

  let(:invalid_attributes) do
    {
      channel_type: 'invalid_type',
      email_address: 'invalid-email',
      enabled: nil
    }
  end

  let(:browser_channel) { UserNotificationChannel.create!(valid_browser_attributes) }
  let(:email_channel) { UserNotificationChannel.create!(valid_email_attributes) }

  describe 'GET /api/v1/user_notification_channels' do
    before do
      create_list(:user_notification_channel, 3)
    end

    it 'returns a list of notification channels' do
      get '/api/v1/user_notification_channels'
      
      expect(response).to have_http_status(:ok)
      expect(json_response['status']).to eq('success')
      expect(json_response['data']).to be_an(Array)
      expect(json_response['data'].length).to eq(3)
      expect(json_response['message']).to eq('Notification channels retrieved successfully')
    end

    it 'returns empty array when no channels exist' do
      UserNotificationChannel.destroy_all
      
      get '/api/v1/user_notification_channels'
      
      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to eq([])
    end
  end

  describe 'GET /api/v1/user_notification_channels/:id' do
    context 'when channel exists' do
      it 'returns the browser notification channel' do
        get "/api/v1/user_notification_channels/#{browser_channel.id}"
        
        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['id']).to eq(browser_channel.id)
        expect(json_response['data']['channel_type']).to eq('browser')
        expect(json_response['message']).to eq('Notification channel retrieved successfully')
      end

      it 'returns the email notification channel' do
        get "/api/v1/user_notification_channels/#{email_channel.id}"
        
        expect(response).to have_http_status(:ok)
        expect(json_response['data']['channel_type']).to eq('email')
        expect(json_response['data']['email_address']).to eq('test@example.com')
      end
    end

    context 'when channel does not exist' do
      it 'returns not found error' do
        get '/api/v1/user_notification_channels/99999'
        
        expect(response).to have_http_status(:not_found)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Notification channel not found')
      end
    end
  end

  describe 'POST /api/v1/user_notification_channels' do
    context 'with valid browser channel attributes' do
      it 'creates a new browser notification channel' do
        expect {
          post '/api/v1/user_notification_channels', params: { user_notification_channel: valid_browser_attributes }
        }.to change(UserNotificationChannel, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['channel_type']).to eq('browser')
        expect(json_response['data']['enabled']).to be true
        expect(json_response['message']).to eq('Notification channel created successfully')
      end
    end

    context 'with valid email channel attributes' do
      it 'creates a new email notification channel' do
        expect {
          post '/api/v1/user_notification_channels', params: { user_notification_channel: valid_email_attributes }
        }.to change(UserNotificationChannel, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['channel_type']).to eq('email')
        expect(json_response['data']['email_address']).to eq('test@example.com')
        expect(json_response['message']).to eq('Notification channel created successfully')
      end

      it 'normalizes email address to lowercase' do
        post '/api/v1/user_notification_channels', params: { 
          user_notification_channel: valid_email_attributes.merge(email_address: 'TEST@EXAMPLE.COM') 
        }

        expect(response).to have_http_status(:created)
        expect(json_response['data']['email_address']).to eq('test@example.com')
      end
    end

    context 'with invalid attributes' do
      it 'returns validation errors for invalid channel type' do
        post '/api/v1/user_notification_channels', params: { 
          user_notification_channel: valid_browser_attributes.merge(channel_type: 'invalid_type') 
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['status']).to eq('error')
        expect(json_response['errors']).to include('Channel type is not included in the list')
        expect(json_response['message']).to eq('Failed to create notification channel')
      end

      it 'returns validation errors for invalid email format' do
        post '/api/v1/user_notification_channels', params: { 
          user_notification_channel: valid_email_attributes.merge(email_address: 'invalid-email') 
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Email address is invalid')
      end

      it 'requires email address for email channels' do
        post '/api/v1/user_notification_channels', params: { 
          user_notification_channel: valid_email_attributes.merge(email_address: '') 
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include("Email address can't be blank")
      end
    end
  end

  describe 'PUT /api/v1/user_notification_channels/:id' do
    context 'with valid attributes' do
      it 'updates the browser notification channel' do
        put "/api/v1/user_notification_channels/#{browser_channel.id}", params: { 
          user_notification_channel: { enabled: false, preferences: { sound: false }.to_json } 
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['enabled']).to be false
        expect(json_response['message']).to eq('Notification channel updated successfully')
      end

      it 'updates the email notification channel' do
        put "/api/v1/user_notification_channels/#{email_channel.id}", params: { 
          user_notification_channel: { email_address: 'newemail@example.com' } 
        }

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['email_address']).to eq('newemail@example.com')
      end
    end

    context 'with invalid attributes' do
      it 'returns validation errors' do
        put "/api/v1/user_notification_channels/#{email_channel.id}", params: { 
          user_notification_channel: { email_address: 'invalid-email' } 
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['status']).to eq('error')
        expect(json_response['errors']).to include('Email address is invalid')
      end
    end

    context 'when channel does not exist' do
      it 'returns not found error' do
        put '/api/v1/user_notification_channels/99999', params: { 
          user_notification_channel: { enabled: false } 
        }

        expect(response).to have_http_status(:not_found)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Notification channel not found')
      end
    end
  end

  describe 'DELETE /api/v1/user_notification_channels/:id' do
    it 'deletes the notification channel' do
      channel_to_delete = browser_channel
      
      expect {
        delete "/api/v1/user_notification_channels/#{channel_to_delete.id}"
      }.to change(UserNotificationChannel, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_response['status']).to eq('success')
      expect(json_response['message']).to eq('Notification channel deleted successfully')
    end

    context 'when channel does not exist' do
      it 'returns not found error' do
        delete '/api/v1/user_notification_channels/99999'

        expect(response).to have_http_status(:not_found)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Notification channel not found')
      end
    end
  end

  describe 'PATCH /api/v1/user_notification_channels/:id/toggle' do
    it 'toggles the enabled status' do
      expect(browser_channel.enabled).to be true

      patch "/api/v1/user_notification_channels/#{browser_channel.id}/toggle"

      expect(response).to have_http_status(:ok)
      expect(json_response['status']).to eq('success')
      expect(json_response['data']['enabled']).to be false
      expect(json_response['message']).to eq('Notification channel disabled successfully')

      patch "/api/v1/user_notification_channels/#{browser_channel.id}/toggle"

      expect(json_response['data']['enabled']).to be true
      expect(json_response['message']).to eq('Notification channel enabled successfully')
    end

    context 'when channel does not exist' do
      it 'returns not found error' do
        patch '/api/v1/user_notification_channels/99999/toggle'

        expect(response).to have_http_status(:not_found)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Notification channel not found')
      end
    end
  end

  describe 'POST /api/v1/user_notification_channels/:id/test' do
    context 'for browser notification channel' do
      it 'returns success for browser test' do
        post "/api/v1/user_notification_channels/#{browser_channel.id}/test"

        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Browser notification test initiated')
      end
    end

    context 'for email notification channel' do
      before do
        # Mock Mailgun client to avoid actual API calls during testing
        allow_any_instance_of(Mailgun::Client).to receive(:send_message).and_return(true)
      end

      it 'sends test email successfully' do
        post "/api/v1/user_notification_channels/#{email_channel.id}/test"

        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Test email sent successfully')
      end

      it 'handles email sending failure' do
        allow_any_instance_of(Mailgun::Client).to receive(:send_message).and_raise(StandardError.new('API Error'))

        post "/api/v1/user_notification_channels/#{email_channel.id}/test"

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Failed to send test email')
      end
    end

    context 'for unknown channel type' do
      let(:unknown_channel) { UserNotificationChannel.create!(channel_type: 'unknown', enabled: true) }

      it 'returns bad request error' do
        post "/api/v1/user_notification_channels/#{unknown_channel.id}/test"

        expect(response).to have_http_status(:bad_request)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Unknown notification channel type')
      end
    end

    context 'when channel does not exist' do
      it 'returns not found error' do
        post '/api/v1/user_notification_channels/99999/test'

        expect(response).to have_http_status(:not_found)
        expect(json_response['status']).to eq('error')
        expect(json_response['message']).to eq('Notification channel not found')
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
