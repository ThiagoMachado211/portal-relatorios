class ApplicationController < ActionController::Base
  before_action :track_user_access, if: :user_signed_in?

  protected

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  private

  def track_user_access
    return unless current_user
    return unless current_user.respond_to?(:access_count) && current_user.respond_to?(:last_access_at)

    if session[:last_tracked_user_id] != current_user.id
      current_user.increment!(:access_count)
      current_user.update_column(:last_access_at, Time.current)
      session[:last_tracked_user_id] = current_user.id
    end
  rescue StandardError
  end
end