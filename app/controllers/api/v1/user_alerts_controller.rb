class Api::V1::UserAlertsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_user_alert, only: [:show, :update, :destroy]

  # GET /api/v1/user_alerts
  def index
    @user_alerts = UserAlert.all
    render json: {
      status: 'success',
      data: @user_alerts,
      message: 'User alerts retrieved successfully'
    }
  end

  # GET /api/v1/user_alerts/:id
  def show
    render json: {
      status: 'success',
      data: @user_alert,
      message: 'User alert retrieved successfully'
    }
  end

  # POST /api/v1/user_alerts
  def create
    @user_alert = UserAlert.new(user_alert_params)

    if @user_alert.save
      render json: {
        status: 'success',
        data: @user_alert,
        message: 'User alert created successfully'
      }, status: :created
    else
      render json: {
        status: 'error',
        errors: @user_alert.errors.full_messages,
        message: 'Failed to create user alert'
      }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/user_alerts/:id
  def update
    if @user_alert.update(user_alert_params)
      render json: {
        status: 'success',
        data: @user_alert,
        message: 'User alert updated successfully'
      }
    else
      render json: {
        status: 'error',
        errors: @user_alert.errors.full_messages,
        message: 'Failed to update user alert'
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/user_alerts/:id
  def destroy
    @user_alert.destroy
    render json: {
      status: 'success',
      message: 'User alert deleted successfully'
    }
  end

  # PATCH /api/v1/user_alerts/:id/toggle
  def toggle
    @user_alert.update(enabled: !@user_alert.enabled)
    render json: {
      status: 'success',
      data: @user_alert,
      message: "User alert #{@user_alert.enabled? ? 'enabled' : 'disabled'} successfully"
    }
  end

  # GET /api/v1/user_alerts/check_triggers
  def check_triggers
    current_prices = params[:current_prices] || {}
    triggered_alerts = []

    UserAlert.where(enabled: true).each do |alert|
      current_price = current_prices[alert.symbol]&.to_f
      next unless current_price

      if should_trigger_alert?(alert, current_price)
        triggered_alerts << {
          alert_id: alert.id,
          symbol: alert.symbol,
          target_price: alert.target_price,
          current_price: current_price,
          alert_type: alert.alert_type,
          triggered_at: Time.current
        }
      end
    end

    render json: {
      status: 'success',
      data: triggered_alerts,
      message: "Found #{triggered_alerts.count} triggered alerts"
    }
  end

  private

  def set_user_alert
    @user_alert = UserAlert.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'User alert not found'
    }, status: :not_found
  end

  def user_alert_params
    params.require(:user_alert).permit(
      :symbol,
      :target_price,
      :alert_type,
      :enabled,
      :user_id,
      :notification_channel_id
    )
  end

  def should_trigger_alert?(alert, current_price)
    case alert.alert_type
    when 'above'
      current_price >= alert.target_price
    when 'below'
      current_price <= alert.target_price
    else
      false
    end
  end
end
