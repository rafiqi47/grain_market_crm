class ProductBatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product
  before_action :set_product_batch, only: [:edit, :update, :destroy]

  def new
    @product_batch = @product.product_batches.build
  end

  def create
    # 1. Gather form input measurements and explicitly tie it to the product ID
    batch_params = product_batch_params.to_h.merge(
      organization_id: current_user.organization.id,
      product_id: @product.id, # <-- THE CRITICAL FIX
      quantity_on_hand: product_batch_params[:initial_quantity]
    )

    # 2. Extract financial structure values
    qty = batch_params[:initial_quantity].to_i
    unit_cost = batch_params[:purchase_price_per_unit].to_f
    total_cost = qty * unit_cost

    amount_paid = params.dig(:financials, :amount_paid).to_f
    amount_on_credit = total_cost - amount_paid

    # 3. Assemble the transaction parameter blocks for our pipeline service
    order_params = {
      total_amount: total_cost,
      amount_paid: amount_paid,
      amount_on_credit: amount_on_credit,
      transaction_date: Date.current,
      invoice_number: "BATCH-REC-#{SecureRandom.hex(3).upcase}"
    }

    batches_params = [batch_params]

    # 4. Trigger the multi-tenant row locking accounting service block
    service = Inventory::ReceiveStockService.new(
      organization: current_user.organization,
      supplier: @product.supplier,
      order_params: order_params,
      batches_params: batches_params
    )

    if service.call
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Stock batch ingested and ledger records successfully updated." }
        format.html { redirect_to dashboard_path, notice: "Stock batch ingested and ledger records updated." }
      end
    else
      # Re-initialize basic invalid object status for view validation errors
      @product_batch = @product.product_batches.build(product_batch_params)
      flash.now[:alert] = service.errors.to_sentence
      render :new, status: :unprocessable_entity
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
