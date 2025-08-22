class Api::V1::UserNotificationChannelsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_notification_channel, only: [:show, :update, :destroy]

  # GET /api/v1/user_notification_channels
  def index
    @notification_channels = UserNotificationChannel.all
    
    # Apply filters
    @notification_channels = @notification_channels.where(channel_type: params[:channel_type]) if params[:channel_type].present?
    @notification_channels = @notification_channels.where(enabled: params[:enabled]) if params[:enabled].present?
    
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
    when 'telegram'
      # Send test Telegram message
      if send_test_telegram(@notification_channel)
        render json: {
          status: 'success',
          message: 'Test Telegram message sent successfully'
        }
      else
        render json: {
          status: 'error',
          message: 'Failed to send test Telegram message'
        }, status: :unprocessable_entity
      end
    when 'log_file'
      # Write test message to log file
      if write_test_log(@notification_channel)
        render json: {
          status: 'success',
          message: 'Test log message written successfully'
        }
      else
        render json: {
          status: 'error',
          message: 'Failed to write test log message'
        }, status: :unprocessable_entity
      end
    when 'os_notification'
      # Send test OS notification
      if send_test_os_notification(@notification_channel)
        render json: {
          status: 'success',
          message: 'Test OS notification sent successfully'
        }
      else
        render json: {
          status: 'error',
          message: 'Failed to send test OS notification'
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
      :telegram_chat_id,
      :telegram_bot_token,
      :log_file_path,
      :os_notification_settings,
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

  def send_test_telegram(notification_channel)
    return false unless notification_channel.telegram_chat_id.present? && notification_channel.telegram_bot_token.present?

    begin
      # Parse preferences for Telegram settings
      preferences = parse_preferences(notification_channel.preferences)
      
      # Create Telegram bot instance
      require 'telegram/bot'
      bot = Telegram::Bot::Client.new(notification_channel.telegram_bot_token)
      
      # Send test message
      message = "🚨 Test notification from Crypto Alert System!\n\nIf you received this, your Telegram notifications are working correctly!\n\nTimestamp: #{Time.current}"
      
      bot.api.send_message(
        chat_id: notification_channel.telegram_chat_id,
        text: message,
        parse_mode: preferences['parse_mode'] || 'HTML',
        disable_web_page_preview: preferences['disable_web_page_preview'] || false
      )
      
      Rails.logger.info "Test Telegram message sent successfully to #{notification_channel.telegram_chat_id}"
      true
    rescue => e
      Rails.logger.error "Failed to send test Telegram message: #{e.message}"
      false
    end
  end

  def write_test_log(notification_channel)
    return false unless notification_channel.log_file_path.present?

    begin
      # Parse preferences for log settings
      preferences = parse_preferences(notification_channel.preferences)
      
      # Create log directory if it doesn't exist
      log_dir = File.dirname(notification_channel.log_file_path)
      FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)
      
      # Write test log message
      log_message = "[#{Time.current.strftime('%Y-%m-%d %H:%M:%S')}] [TEST] [#{preferences['log_level'] || 'INFO'}] Test notification from Crypto Alert System - If you see this, your log file notifications are working correctly!\n"
      
      File.open(notification_channel.log_file_path, 'a') do |file|
        file.write(log_message)
      end
      
      Rails.logger.info "Test log message written successfully to #{notification_channel.log_file_path}"
      true
    rescue => e
      Rails.logger.error "Failed to write test log message: #{e.message}"
      false
    end
  end

  def send_test_os_notification(notification_channel)
    begin
      # Parse preferences for OS notification settings
      preferences = parse_preferences(notification_channel.preferences)
      
      # For OS notifications, we'll use system commands
      # This is a basic implementation - you might want to use a gem like 'notify-send' for Linux
      case RUBY_PLATFORM
      when /darwin/ # macOS
        system("osascript -e 'display notification \"Test notification from Crypto Alert System!\" with title \"Crypto Alert Test\" sound name \"Glass\"'")
      when /linux/
        # Try to use notify-send if available
        if system("which notify-send > /dev/null 2>&1")
          priority = preferences['priority'] || 'normal'
          timeout = preferences['timeout'] || 5000
          system("notify-send -u #{priority} -t #{timeout} 'Crypto Alert Test' 'Test notification from Crypto Alert System!'")
        else
          # Fallback to writing to system log
          system("logger -t 'CryptoAlert' 'Test notification from Crypto Alert System!'")
        end
      when /mswin|mingw/ # Windows
        # Use PowerShell to show notification
        script = "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Test notification from Crypto Alert System!', 'Crypto Alert Test', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)"
        system("powershell -Command \"#{script}\"")
      else
        # Fallback to system log
        system("logger -t 'CryptoAlert' 'Test notification from Crypto Alert System!'")
      end
      
      Rails.logger.info "Test OS notification sent successfully"
      true
    rescue => e
      Rails.logger.error "Failed to send test OS notification: #{e.message}"
      false
    end
  end

  def parse_preferences(preferences_json)
    return {} if preferences_json.blank?
    
    begin
      JSON.parse(preferences_json)
    rescue JSON::ParserError
      {}
    end
  end
end
