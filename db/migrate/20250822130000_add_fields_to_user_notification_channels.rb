class AddFieldsToUserNotificationChannels < ActiveRecord::Migration[7.2]
  def change
    add_column :user_notification_channels, :telegram_chat_id, :string
    add_column :user_notification_channels, :telegram_bot_token, :string
    add_column :user_notification_channels, :log_file_path, :string
    add_column :user_notification_channels, :os_notification_settings, :text
    
    add_index :user_notification_channels, :telegram_chat_id
    add_index :user_notification_channels, :log_file_path
  end
end
