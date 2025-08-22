class CreateUserNotificationChannels < ActiveRecord::Migration[7.2]
  def change
    create_table :user_notification_channels do |t|
      t.string :channel_type
      t.string :email_address
      t.boolean :enabled
      t.integer :user_id
      t.text :preferences

      t.timestamps
    end
  end
end
