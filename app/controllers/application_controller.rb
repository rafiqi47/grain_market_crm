class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Only allow valid HTML/JS requests
  protect_from_forgery with: :exception

  private

  # Devise hook executed automatically upon successful authentication
  def after_sign_in_path_for(resource)
    # Redirect dynamically based on the user's role assignment
    case resource.role
    when "super_admin"
      admin_root_path
    when "owner"
      dashboard_path(anchor: "enterprise-metrics")
    when "manager"
      dashboard_path(anchor: "trading-desk")
    else
      root_path
    end
  end
end
