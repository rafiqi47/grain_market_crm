class ProductBatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product
  before_action :set_product_batch, only: [:edit, :update, :destroy]

  def new
    @product_batch = @product.product_batches.build
  end

  def create
    unit = @product.unit.to_s

    batch_attrs = {
      organization_id:  current_user.organization.id,
      product_id:       @product.id,
      batch_number:     params[:product_batch][:batch_number].presence,
      manufacture_date: params[:product_batch][:manufacture_date].presence,
      expiry_date:      params[:product_batch][:expiry_date].presence
    }

    case unit
    when "kg"
      maund   = params[:product_batch][:quantity_maund].to_f
      kg      = params[:product_batch][:quantity_kg].to_f
      total_kg = maund * 40 + kg
      ppm     = params[:product_batch][:price_per_maund].to_f
      batch_attrs.merge!(
        initial_quantity:        total_kg,
        quantity_on_hand:        total_kg,
        purchase_price_per_unit: ppm > 0 ? ppm / 40.0 : 0
      )
    when "ml", "gram"
      pc   = params[:product_batch][:packet_count].to_f
      ps   = params[:product_batch][:package_size].to_f
      ppp  = params[:product_batch][:price_per_packet].to_f
      total_qty = pc * ps
      batch_attrs.merge!(
        initial_quantity:        total_qty,
        quantity_on_hand:        total_qty,
        purchase_price_per_unit: ps > 0 ? ppp / ps : 0,
        package_size:            ps
      )
    else
      qty = params[:product_batch][:initial_quantity].to_f
      batch_attrs.merge!(
        initial_quantity:        qty,
        quantity_on_hand:        qty,
        purchase_price_per_unit: params[:product_batch][:purchase_price_per_unit].to_f
      )
    end

    qty        = batch_attrs[:initial_quantity].to_f
    unit_cost  = batch_attrs[:purchase_price_per_unit].to_f
    total_cost = qty * unit_cost

    amount_paid      = params.dig(:financials, :amount_paid).to_f
    amount_on_credit = total_cost - amount_paid

    service = Inventory::ReceiveStockService.new(
      organization:   current_user.organization,
      supplier:       @product.supplier,
      order_params:   {
        total_amount:     total_cost,
        amount_paid:      amount_paid,
        amount_on_credit: amount_on_credit,
        transaction_date: Date.current,
        invoice_number:   "BATCH-REC-#{SecureRandom.hex(3).upcase}"
      },
      batches_params: [batch_attrs]
    )

    if service.call
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Stock batch added successfully." }
        format.html { redirect_to dashboard_path, notice: "Stock batch added." }
      end
    else
      @product_batch = @product.product_batches.build
      flash.now[:alert] = service.errors.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    unit = @product.unit.to_s

    old_quantity = @product_batch.quantity_on_hand
    old_price    = @product_batch.purchase_price_per_unit

    update_attrs = {
      batch_number:     params[:product_batch][:batch_number].presence,
      manufacture_date: params[:product_batch][:manufacture_date].presence,
      expiry_date:      params[:product_batch][:expiry_date].presence
    }

    case unit
    when "kg"
      maund    = params[:product_batch][:quantity_maund].to_f
      kg       = params[:product_batch][:quantity_kg].to_f
      total_kg = maund * 40 + kg
      ppm      = params[:product_batch][:price_per_maund].to_f
      update_attrs.merge!(
        quantity_on_hand:        total_kg,
        purchase_price_per_unit: ppm > 0 ? ppm / 40.0 : 0
      )
    when "ml", "gram"
      pc       = params[:product_batch][:packet_count].to_f
      ps       = params[:product_batch][:package_size].to_f
      ppp      = params[:product_batch][:price_per_packet].to_f
      total_qty = pc * ps
      update_attrs.merge!(
        quantity_on_hand:        total_qty,
        purchase_price_per_unit: ps > 0 ? ppp / ps : 0,
        package_size:            ps
      )
    else
      update_attrs.merge!(
        quantity_on_hand:        params[:product_batch][:quantity_on_hand].to_f,
        purchase_price_per_unit: params[:product_batch][:purchase_price_per_unit].to_f
      )
    end

    new_quantity = update_attrs[:quantity_on_hand]
    new_price    = update_attrs[:purchase_price_per_unit]

    if @product_batch.update(update_attrs)
      if new_quantity != old_quantity || new_price != old_price
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
        format.html { redirect_to dashboard_path, notice: "Batch updated." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    old_quantity = @product_batch.quantity_on_hand
    old_price    = @product_batch.purchase_price_per_unit

    @product_batch.destroy

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
      format.turbo_stream { flash.now[:notice] = "Batch removed and ledger adjusted." }
      format.html { redirect_to dashboard_path, notice: "Batch removed." }
    end
  end

  private

  def set_product
    @product = current_user.organization.products.find(params[:product_id])
  end

  def set_product_batch
    @product_batch = @product.product_batches.find(params[:id])
  end
end
