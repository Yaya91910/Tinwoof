class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :touch_last_seen, if: :user_signed_in?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name photo])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name photo bio])
  end

  def touch_last_seen
    current_user.update_column(:last_seen_at, Time.current) unless current_user.online?
  end
end
