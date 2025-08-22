class UserAlert < ApplicationRecord
  belongs_to :user_notification_channel, optional: true
  
  # Validations
  validates :symbol, presence: true, length: { maximum: 20 }
  validates :target_price, presence: true, numericality: { greater_than: 0 }
  validates :alert_type, presence: true, inclusion: { in: %w[above below] }
  validates :enabled, inclusion: { in: [true, false] }
  
  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :by_symbol, ->(symbol) { where(symbol: symbol.upcase) }
  scope :by_type, ->(type) { where(alert_type: type) }
  scope :active, -> { enabled.where('created_at > ?', 30.days.ago) }
  
  # Callbacks
  before_save :normalize_symbol
  after_create :log_alert_creation
  after_update :log_alert_update
  
  # Instance methods
  def trigger_alert?(current_price)
    return false unless enabled?
    
    case alert_type
    when 'above'
      current_price >= target_price
    when 'below'
      current_price <= target_price
    else
      false
    end
  end
  
  def status
    enabled? ? 'active' : 'inactive'
  end
  
  def alert_description
    "#{symbol} #{alert_type} $#{target_price}"
  end
  
  def to_notification_data
    {
      id: id,
      symbol: symbol,
      target_price: target_price,
      alert_type: alert_type,
      created_at: created_at,
      alert_description: alert_description
    }
  end
  
  private
  
  def normalize_symbol
    self.symbol = symbol.upcase if symbol.present?
  end
  
  def log_alert_creation
    Rails.logger.info "User Alert created: #{alert_description} (ID: #{id})"
  end
  
  def log_alert_update
    Rails.logger.info "User Alert updated: #{alert_description} (ID: #{id})"
  end
end
