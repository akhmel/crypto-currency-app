class Api::V1::UserNotificationChannelsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_notification_channel, only: [:show, :update, :destroy]

  # GET /api/v1/user_notification_channels
  def index
    @notification_channels = UserNotificationChannel.all
    render json: {
      status: 'success',
      data: @notification_channels,
      message: 'Notification channels retrieved successfully'
    }
  end

  # GET /api/v1/user_notification_channels/:id
  def show
    render json: {
      status: 'success',
      data: @notification_channel,
      message: 'Notification channel retrieved successfully'
    }
  end

  # POST /api/v1/user_notification_channels
  def create
    @notification_channel = UserNotificationChannel.new(notification_channel_params)

    if @notification_channel.save
      render json: {
        status: 'success',
        data: @notification_channel,
        message: 'Notification channel created successfully'
      }, status: :created
    else
      render json: {
        status: 'error',
        errors: @notification_channel.errors.full_messages,
        message: 'Failed to create notification channel'
      }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/user_notification_channels/:id
  def update
    if @notification_channel.update(notification_channel_params)
      render json: {
        status: 'success',
        data: @notification_channel,
        message: 'Notification channel updated successfully'
      }
    else
      render json: {
        status: 'error',
        errors: @notification_channel.errors.full_messages,
        message: 'Failed to update notification channel'
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/user_notification_channels/:id
  def destroy
    @notification_channel.destroy
    render json: {
      status: 'success',
      message: 'Notification channel deleted successfully'
    }
  end

  # PATCH /api/v1/user_notification_channels/:id/toggle
  def toggle
    @notification_channel.update(enabled: !@notification_channel.enabled)
    render json: {
      status: 'success',
      data: @notification_channel,
      message: "Notification channel #{@notification_channel.enabled? ? 'enabled' : 'disabled'} successfully"
    }
  end

  # POST /api/v1/user_notification_channels/:id/test
  def test
    case @notification_channel.channel_type
    when 'browser'
      # For browser notifications, we'll just return success
      # The actual notification will be handled by the frontend
      render json: {
        status: 'success',
        message: 'Browser notification test initiated'
      }
    when 'email'
      # Send test email using Mailgun
      if send_test_email(@notification_channel)
        render json: {
          status: 'success',
          message: 'Test email sent successfully'
        }
      else
        render json: {
          status: 'error',
          message: 'Failed to send test email'
        }, status: :unprocessable_entity
      end
    else
      render json: {
        status: 'error',
        message: 'Unknown notification channel type'
      }, status: :bad_request
    end
  end

  private

  def set_notification_channel
    @notification_channel = UserNotificationChannel.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Notification channel not found'
    }, status: :not_found
  end

  def notification_channel_params
    params.require(:user_notification_channel).permit(
      :channel_type,
      :email_address,
      :enabled,
      :user_id,
      :preferences
    )
  end

  def send_test_email(notification_channel)
    return false unless notification_channel.email_address.present?

    begin
      # Configure Mailgun
      mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      
      # Message parameters
      message_params = {
        from: ENV['MAILGUN_FROM_EMAIL'] || 'noreply@yourdomain.com',
        to: notification_channel.email_address,
        subject: 'Crypto Alert System - Test Email',
        text: "This is a test email from your crypto alert system.\n\nIf you received this, your email notifications are working correctly!\n\nTimestamp: #{Time.current}"
      }

      # Send the email
      mg_client.send_message(ENV['MAILGUN_DOMAIN'], message_params)
      
      # Log the successful email
      Rails.logger.info "Test email sent successfully to #{notification_channel.email_address}"
      true
    rescue => e
      Rails.logger.error "Failed to send test email: #{e.message}"
      false
    end
  end
end
