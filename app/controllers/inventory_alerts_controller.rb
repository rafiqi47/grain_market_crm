class InventoryAlertsController < ApplicationController
  before_action :authenticate_user!

  def mark_as_read
    # Scope lookups securely to the logged-in user's company tenant
    @alert = current_user.organization.inventory_alerts.find(params[:id])
    @alert.mark_as_read!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@alert) }
      format.html { redirect_to dashboard_path, notice: "Alert dismissed." }
    end
  end
end
