FactoryBot.define do
  factory :user_alert do
    symbol { 'BTCUSDT' }
    target_price { 50000.0 }
    alert_type { 'above' }
    enabled { true }
    user_id { 1 }
    notification_channel_id { 1 }

    trait :below do
      alert_type { 'below' }
    end

    trait :disabled do
      enabled { false }
    end

    trait :eth do
      symbol { 'ETHUSDT' }
      target_price { 3000.0 }
    end

    trait :ada do
      symbol { 'ADAUSDT' }
      target_price { 1.0 }
    end

    trait :sol do
      symbol { 'SOLUSDT' }
      target_price { 100.0 }
    end
  end
end
