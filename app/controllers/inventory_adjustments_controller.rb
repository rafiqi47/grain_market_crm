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

  def edit
    @adjustment = current_user.organization.inventory_adjustments.find(params[:id])
  end

  def update
    @adjustment = current_user.organization.inventory_adjustments.find(params[:id])

    # Logic: Use a service to handle the reversal of the old adjustment
    # and the application of the new one to keep stock accurate.
    if Inventory::UpdateAdjustmentService.new(@adjustment, adjustment_params).call
      redirect_to inventory_adjustments_path, notice: "Ledger entry updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def reverse
    @adjustment = current_user.organization.inventory_adjustments.find(params[:id])

    if Inventory::ReverseAdjustmentService.new(@adjustment, current_user).call
      redirect_to inventory_adjustments_path, notice: "Adjustment has been reversed successfully."
    else
      redirect_to inventory_adjustments_path, alert: "Reversal failed."
    end
  end
end
