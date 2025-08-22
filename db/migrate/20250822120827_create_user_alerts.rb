class CreateUserAlerts < ActiveRecord::Migration[7.2]
  def change
    create_table :user_alerts do |t|
      t.string :symbol
      t.decimal :target_price
      t.string :alert_type
      t.boolean :enabled
      t.integer :user_id
      t.integer :notification_channel_id

      t.timestamps
    end
  end
end
