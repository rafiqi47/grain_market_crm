class ProductBatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product
  before_action :set_product_batch, only: [:edit, :update, :destroy]

  def new
    @product_batch = @product.product_batches.build
  end

  def create
    @product_batch = @product.product_batches.build(product_batch_params)
    @product_batch.quantity_on_hand = @product_batch.initial_quantity

    if @product_batch.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Lot Batch registered successfully." }
        format.html { redirect_to dashboard_path, notice: "Lot Batch registered successfully." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Renders your app/views/product_batches/edit.html.erb modal
  end

  def update
    if @product_batch.update(product_batch_params)
      respond_to do |format|
        # CRITICAL FIX: Directs response to look for update.turbo_stream.erb
        format.turbo_stream { flash.now[:notice] = "Lot Batch updated successfully." }
        format.html { redirect_to dashboard_path, notice: "Lot Batch updated successfully." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product_batch.destroy
    respond_to do |format|
      # CRITICAL FIX: Directs response to look for destroy.turbo_stream.erb
      format.turbo_stream { flash.now[:notice] = "Lot Batch removed successfully." }
      format.html { redirect_to dashboard_path, notice: "Lot Batch removed successfully." }
    end
  end

  private

  def set_product
    @product = current_user.organization.products.find(params[:product_id])
  end

  def set_product_batch
    @product_batch = @product.product_batches.find(params[:id])
  end

  def product_batch_params
    params.require(:product_batch).permit(:batch_number, :initial_quantity, :quantity_on_hand, :manufacture_date, :expiry_date, :purchase_price_per_unit)
  end
end
