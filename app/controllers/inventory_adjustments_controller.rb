# app/controllers/inventory_adjustments_controller.rb
class InventoryAdjustmentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @adjustments = current_user.organization.inventory_adjustments.includes(:product_batch, :user).order(created_at: :desc)
    @unread_alerts = current_user.organization.inventory_alerts.unread.latest
  end

  def new
    @batches = current_user.organization.product_batches.active.includes(:product)
  end

  def create
    service = Inventory::AdjustStockService.new(
      organization: current_user.organization,
      user: current_user,
      product_batch_id: params[:product_batch_id],
      quantity_changed: params[:quantity_changed],
      reason: params[:reason],
      notes: params[:notes]
    )

    if service.call
      redirect_to inventory_adjustments_path, notice: "Inventory adjustment written to historical ledger successfully."
    else
      flash.now[:alert] = service.errors.join(", ")
      @batches = current_user.organization.product_batches.active.includes(:product)
      render :new, status: :unprocessable_entity
    end
  end
end
