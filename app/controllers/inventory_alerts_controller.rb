class InventoryAlertsController < ApplicationController
  before_action :authenticate_user!

  def index
    @alerts = current_user.organization.inventory_alerts
                          .unread
                          .latest
                          .includes(product_batch: :product)
  end

  def mark_as_read
    @alert = current_user.organization.inventory_alerts.find(params[:id])
    @alert.update!(read_at: Time.current)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@alert) }
      format.html { redirect_to dashboard_path, notice: "Alert acknowledged." }
    end
  end
end
