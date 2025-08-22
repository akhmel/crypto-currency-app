FactoryBot.define do
  factory :user_notification_channel do
    user_id { 1 }

    trait :browser do
      channel_type { 'browser' }
      enabled { true }
      preferences { { sound: true, duration: 5000 }.to_json }
    end

    trait :email do
      channel_type { 'email' }
      email_address { 'test@example.com' }
      enabled { true }
      preferences { { html_format: true, frequency: 'immediate' }.to_json }
    end

    trait :disabled do
      enabled { false }
    end

    trait :custom_preferences do
      preferences { { custom_setting: 'value' }.to_json }
    end

    # Default to browser channel
    browser
  end
end
