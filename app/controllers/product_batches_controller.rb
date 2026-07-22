class ProductBatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product
  before_action :set_product_batch, only: [:edit, :update, :destroy]

  def new
    @product_batch = @product.product_batches.build
  end

  def create
    batch_params = product_batch_params.to_h.merge(
      organization_id: current_user.organization.id,
      product_id:      @product.id,
      quantity_on_hand: product_batch_params[:initial_quantity]
    )

    qty        = batch_params[:initial_quantity].to_f
    unit_cost  = batch_params[:purchase_price_per_unit].to_f
    total_cost = qty * unit_cost

    amount_paid      = params.dig(:financials, :amount_paid).to_f
    amount_on_credit = total_cost - amount_paid

    order_params = {
      total_amount:     total_cost,
      amount_paid:      amount_paid,
      amount_on_credit: amount_on_credit,
      transaction_date: Date.current,
      invoice_number:   "BATCH-REC-#{SecureRandom.hex(3).upcase}"
    }

    service = Inventory::ReceiveStockService.new(
      organization:   current_user.organization,
      supplier:       @product.supplier,
      order_params:   order_params,
      batches_params: [batch_params]
    )

    if service.call
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Stock batch ingested and ledger records successfully updated." }
        format.html { redirect_to dashboard_path, notice: "Stock batch ingested and ledger records updated." }
      end
    else
      @product_batch = @product.product_batches.build(product_batch_params)
      flash.now[:alert] = service.errors.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Capture old values BEFORE the update so we can calculate the difference
    old_quantity = @product_batch.quantity_on_hand
    old_price    = @product_batch.purchase_price_per_unit

    new_quantity = product_batch_params[:quantity_on_hand].to_f
    new_price    = product_batch_params[:purchase_price_per_unit].to_f

    quantity_changed = new_quantity != old_quantity
    price_changed    = new_price    != old_price

    if @product_batch.update(product_batch_params)
      if quantity_changed || price_changed
        service = Inventory::AdjustBatchService.new(
          batch:        @product_batch,
          old_quantity: old_quantity,
          old_price:    old_price,
          new_quantity: new_quantity,
          new_price:    new_price,
          organization: current_user.organization
        )

        unless service.call
          flash.now[:alert] = "Batch saved but ledger adjustment failed: #{service.errors.join(', ')}"
        end
      end

      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Batch updated successfully." }
        format.html { redirect_to product_path(@product), notice: "Batch updated successfully." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    # Capture values before destroy since batch is gone after
    old_quantity = @product_batch.quantity_on_hand
    old_price    = @product_batch.purchase_price_per_unit

    @product_batch.destroy

    # Reverse the full batch value from the ledger
    service = Inventory::AdjustBatchService.new(
      batch:        @product_batch,
      old_quantity: old_quantity,
      old_price:    old_price,
      new_quantity: 0,
      new_price:    0,
      organization: current_user.organization
    )

    unless service.call
      flash.now[:alert] = "Batch removed but ledger adjustment failed: #{service.errors.join(', ')}"
    end

    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "Lot batch removed and ledger adjusted." }
      format.html { redirect_to dashboard_path, notice: "Lot batch removed and ledger adjusted." }
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
    params.require(:product_batch).permit(
      :batch_number, :initial_quantity, :quantity_on_hand,
      :manufacture_date, :expiry_date, :purchase_price_per_unit
    )
  end
end
