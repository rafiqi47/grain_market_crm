class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @organization = current_user.organization

    # Load unread expiration notifications for this specific organization tenant
    @unread_alerts = @organization.inventory_alerts.unread.latest.includes(product_batch: :product)

    # Load product catalog breakdown
    @products = @organization.products.includes(:product_batches, :supplier).order(:name)
  end
end
