class UserNotificationChannel < ApplicationRecord
  has_many :user_alerts, dependent: :nullify
  
  # Validations
  validates :channel_type, presence: true, inclusion: { in: %w[browser email telegram log_file os_notification] }
  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :email_channel?
  validates :telegram_chat_id, presence: true, if: :telegram_channel?
  validates :telegram_bot_token, presence: true, if: :telegram_channel?
  validates :log_file_path, presence: true, if: :log_file_channel?
  validates :enabled, inclusion: { in: [true, false] }
  
  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :by_type, ->(type) { where(channel_type: type) }
  scope :browser_channels, -> { where(channel_type: 'browser') }
  scope :email_channels, -> { where(channel_type: 'email') }
  scope :telegram_channels, -> { where(channel_type: 'telegram') }
  scope :log_file_channels, -> { where(channel_type: 'log_file') }
  scope :os_notification_channels, -> { where(channel_type: 'os_notification') }
  scope :active, -> { enabled.where('created_at > ?', 30.days.ago) }
  
  # Callbacks
  before_save :normalize_email_address
  after_create :log_channel_creation
  after_update :log_channel_update
  
  # Instance methods
  def browser_channel?
    channel_type == 'browser'
  end
  
  def email_channel?
    channel_type == 'email'
  end

  def telegram_channel?
    channel_type == 'telegram'
  end

  def log_file_channel?
    channel_type == 'log_file'
  end

  def os_notification_channel?
    channel_type == 'os_notification'
  end
  
  def status
    enabled? ? 'active' : 'inactive'
  end
  
  def channel_description
    case channel_type
    when 'browser'
      'Browser Notifications'
    when 'email'
      "Email: #{email_address}"
    when 'telegram'
      "Telegram: #{telegram_chat_id}"
    when 'log_file'
      "Log File: #{log_file_path}"
    when 'os_notification'
      'OS Notifications'
    else
      'Unknown Channel'
    end
  end
  
  def send_notification(alert_data)
    case channel_type
    when 'browser'
      # Browser notifications are handled by the frontend
      # We just log that it should be sent
      Rails.logger.info "Browser notification should be sent for alert: #{alert_data[:alert_description]}"
      true
    when 'email'
      send_email_notification(alert_data)
    when 'telegram'
      send_telegram_notification(alert_data)
    when 'log_file'
      write_log_notification(alert_data)
    when 'os_notification'
      send_os_notification(alert_data)
    else
      false
    end
  end
  
  def send_test_notification
    case channel_type
    when 'browser'
      true # Browser test is handled by frontend
    when 'email'
      send_test_email
    when 'telegram'
      send_test_telegram
    when 'log_file'
      write_test_log
    when 'os_notification'
      send_test_os_notification
    else
      false
    end
  end
  
  def preferences_hash
    return {} if preferences.blank?
    
    begin
      JSON.parse(preferences)
    rescue JSON::ParserError
      {}
    end
  end
  
  def update_preferences(new_preferences)
    current_prefs = preferences_hash
    merged_prefs = current_prefs.merge(new_preferences.stringify_keys)
    update(preferences: merged_prefs.to_json)
  end
  
  private
  
  def normalize_email_address
    self.email_address = email_address.downcase.strip if email_address.present?
  end
  
  def log_channel_creation
    Rails.logger.info "Notification Channel created: #{channel_description} (ID: #{id})"
  end
  
  def log_channel_update
    Rails.logger.info "Notification Channel updated: #{channel_description} (ID: #{id})"
  end
  
  def send_email_notification(alert_data)
    return false unless email_channel? && email_address.present?
    
    begin
      # Configure Mailgun
      mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      
      # Message parameters
      message_params = {
        from: ENV['MAILGUN_FROM_EMAIL'] || 'noreply@yourdomain.com',
        to: email_address,
        subject: "🚨 Crypto Alert: #{alert_data[:symbol]} #{alert_data[:alert_type]} $#{alert_data[:target_price]}",
        text: build_alert_email_text(alert_data),
        html: build_alert_email_html(alert_data)
      }

      # Send the email
      mg_client.send_message(ENV['MAILGUN_DOMAIN'], message_params)
      
      # Log the successful email
      Rails.logger.info "Alert email sent successfully to #{email_address} for #{alert_data[:symbol]}"
      true
    rescue => e
      Rails.logger.error "Failed to send alert email: #{e.message}"
      false
    end
  end

  def send_telegram_notification(alert_data)
    return false unless telegram_channel? && telegram_chat_id.present? && telegram_bot_token.present?
    
    begin
      require 'telegram/bot'
      bot = Telegram::Bot::Client.new(telegram_bot_token)
      
      # Build message
      message = build_telegram_message(alert_data)
      
      # Parse preferences
      prefs = preferences_hash
      
      # Send message
      bot.api.send_message(
        chat_id: telegram_chat_id,
        text: message,
        parse_mode: prefs['parse_mode'] || 'HTML',
        disable_web_page_preview: prefs['disable_web_page_preview'] || false
      )
      
      Rails.logger.info "Alert Telegram message sent successfully to #{telegram_chat_id} for #{alert_data[:symbol]}"
      true
    rescue => e
      Rails.logger.error "Failed to send alert Telegram message: #{e.message}"
      false
    end
  end

  def write_log_notification(alert_data)
    return false unless log_file_channel? && log_file_path.present?
    
    begin
      # Parse preferences
      prefs = preferences_hash
      
      # Create log directory if it doesn't exist
      log_dir = File.dirname(log_file_path)
      FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)
      
      # Build log message
      log_message = build_log_message(alert_data, prefs)
      
      # Write to log file
      File.open(log_file_path, 'a') do |file|
        file.write(log_message)
      end
      
      Rails.logger.info "Alert log message written successfully to #{log_file_path} for #{alert_data[:symbol]}"
      true
    rescue => e
      Rails.logger.error "Failed to write alert log message: #{e.message}"
      false
    end
  end

  def send_os_notification(alert_data)
    begin
      # Parse preferences
      prefs = preferences_hash
      
      # Build notification message
      title = "🚨 Crypto Alert: #{alert_data[:symbol]}"
      message = "#{alert_data[:alert_type].upcase} $#{alert_data[:target_price]} - Current: $#{alert_data[:current_price]}"
      
      # Send OS notification based on platform
      case RUBY_PLATFORM
      when /darwin/ # macOS
        system("osascript -e 'display notification \"#{message}\" with title \"#{title}\" sound name \"Glass\"'")
      when /linux/
        if system("which notify-send > /dev/null 2>&1")
          priority = prefs['priority'] || 'normal'
          timeout = prefs['timeout'] || 5000
          system("notify-send -u #{priority} -t #{timeout} '#{title}' '#{message}'")
        else
          system("logger -t 'CryptoAlert' '#{title}: #{message}'")
        end
      when /mswin|mingw/ # Windows
        script = "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('#{message}', '#{title}', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)"
        system("powershell -Command \"#{script}\"")
      else
        system("logger -t 'CryptoAlert' '#{title}: #{message}'")
      end
      
      Rails.logger.info "Alert OS notification sent successfully for #{alert_data[:symbol]}"
      true
    rescue => e
      Rails.logger.error "Failed to send alert OS notification: #{e.message}"
      false
    end
  end
  
  def send_test_email
    return false unless email_channel? && email_address.present?
    
    begin
      # Configure Mailgun
      mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
      
      # Message parameters
      message_params = {
        from: ENV['MAILGUN_FROM_EMAIL'] || 'noreply@yourdomain.com',
        to: email_address,
        subject: 'Crypto Alert System - Test Email',
        text: "This is a test email from your crypto alert system.\n\nIf you received this, your email notifications are working correctly!\n\nTimestamp: #{Time.current}",
        html: "<h2>Test Email</h2><p>This is a test email from your crypto alert system.</p><p>If you received this, your email notifications are working correctly!</p><p><strong>Timestamp:</strong> #{Time.current}</p>"
      }

      # Send the email
      mg_client.send_message(ENV['MAILGUN_DOMAIN'], message_params)
      
      # Log the successful email
      Rails.logger.info "Test email sent successfully to #{email_address}"
      true
    rescue => e
      Rails.logger.error "Failed to send test email: #{e.message}"
      false
    end
  end

  def send_test_telegram
    return false unless telegram_channel? && telegram_chat_id.present? && telegram_bot_token.present?
    
    begin
      require 'telegram/bot'
      bot = Telegram::Bot::Client.new(telegram_bot_token)
      
      message = "🚨 Test notification from Crypto Alert System!\n\nIf you received this, your Telegram notifications are working correctly!\n\nTimestamp: #{Time.current}"
      
      prefs = preferences_hash
      bot.api.send_message(
        chat_id: telegram_chat_id,
        text: message,
        parse_mode: prefs['parse_mode'] || 'HTML',
        disable_web_page_preview: prefs['disable_web_page_preview'] || false
      )
      
      Rails.logger.info "Test Telegram message sent successfully to #{telegram_chat_id}"
      true
    rescue => e
      Rails.logger.error "Failed to send test Telegram message: #{e.message}"
      false
    end
  end

  def write_test_log
    return false unless log_file_channel? && log_file_path.present?
    
    begin
      prefs = preferences_hash
      
      log_dir = File.dirname(log_file_path)
      FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)
      
      log_message = "[#{Time.current.strftime('%Y-%m-%d %H:%M:%S')}] [TEST] [#{prefs['log_level'] || 'INFO'}] Test notification from Crypto Alert System - If you see this, your log file notifications are working correctly!\n"
      
      File.open(log_file_path, 'a') do |file|
        file.write(log_message)
      end
      
      Rails.logger.info "Test log message written successfully to #{log_file_path}"
      true
    rescue => e
      Rails.logger.error "Failed to write test log message: #{e.message}"
      false
    end
  end

  def send_test_os_notification
    begin
      prefs = preferences_hash
      
      case RUBY_PLATFORM
      when /darwin/ # macOS
        system("osascript -e 'display notification \"Test notification from Crypto Alert System!\" with title \"Crypto Alert Test\" sound name \"Glass\"'")
      when /linux/
        if system("which notify-send > /dev/null 2>&1")
          priority = prefs['priority'] || 'normal'
          timeout = prefs['timeout'] || 5000
          system("notify-send -u #{priority} -t #{timeout} 'Crypto Alert Test' 'Test notification from Crypto Alert System!'")
        else
          system("logger -t 'CryptoAlert' 'Test notification from Crypto Alert System!'")
        end
      when /mswin|mingw/ # Windows
        script = "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Test notification from Crypto Alert System!', 'Crypto Alert Test', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)"
        system("powershell -Command \"#{script}\"")
      else
        system("logger -t 'CryptoAlert' 'Test notification from Crypto Alert System!'")
      end
      
      Rails.logger.info "Test OS notification sent successfully"
      true
    rescue => e
      Rails.logger.error "Failed to send test OS notification: #{e.message}"
      false
    end
  end
  
  def build_alert_email_text(alert_data)
    <<~EMAIL
      🚨 CRYPTO ALERT TRIGGERED!
      
      Symbol: #{alert_data[:symbol]}
      Alert Type: #{alert_data[:alert_type].upcase}
      Target Price: $#{alert_data[:target_price]}
      Current Price: $#{alert_data[:current_price]}
      Triggered At: #{alert_data[:triggered_at]}
      
      Your cryptocurrency price alert has been triggered!
      
      ---
      Crypto Alert System
      Sent at: #{Time.current}
    EMAIL
  end
  
  def build_alert_email_html(alert_data)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; }
          .alert { background-color: #ff4444; color: white; padding: 20px; border-radius: 8px; }
          .details { background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-top: 20px; }
          .price { font-size: 24px; font-weight: bold; color: #ff4444; }
        </style>
      </head>
      <body>
        <div class="alert">
          <h1>🚨 CRYPTO ALERT TRIGGERED!</h1>
        </div>
        
        <div class="details">
          <h2>Alert Details</h2>
          <p><strong>Symbol:</strong> #{alert_data[:symbol]}</p>
          <p><strong>Alert Type:</strong> #{alert_data[:alert_type].upcase}</p>
          <p><strong>Target Price:</strong> <span class="price">$#{alert_data[:target_price]}</span></p>
          <p><strong>Current Price:</strong> <span class="price">$#{alert_data[:current_price]}</span></p>
          <p><strong>Triggered At:</strong> #{alert_data[:triggered_at]}</p>
          
          <p>Your cryptocurrency price alert has been triggered!</p>
        </div>
        
        <hr>
        <p><em>Crypto Alert System - Sent at: #{Time.current}</em></p>
      </body>
      </html>
    HTML
  end

  def build_telegram_message(alert_data)
    <<~MESSAGE
      🚨 <b>CRYPTO ALERT TRIGGERED!</b>
      
      <b>Symbol:</b> #{alert_data[:symbol]}
      <b>Alert Type:</b> #{alert_data[:alert_type].upcase}
      <b>Target Price:</b> $#{alert_data[:target_price]}
      <b>Current Price:</b> $#{alert_data[:current_price]}
      <b>Triggered At:</b> #{alert_data[:triggered_at]}
      
      Your cryptocurrency price alert has been triggered!
      
      ---
      <i>Crypto Alert System</i>
      <i>Sent at: #{Time.current}</i>
    MESSAGE
  end

  def build_log_message(alert_data, prefs)
    timestamp = Time.current.strftime('%Y-%m-%d %H:%M:%S')
    log_level = prefs['log_level'] || 'INFO'
    
    <<~LOG
      [#{timestamp}] [ALERT] [#{log_level}] Crypto Alert Triggered - Symbol: #{alert_data[:symbol]}, Type: #{alert_data[:alert_type].upcase}, Target: $#{alert_data[:target_price]}, Current: $#{alert_data[:current_price]}, Triggered: #{alert_data[:triggered_at]}
    LOG
  end
end
