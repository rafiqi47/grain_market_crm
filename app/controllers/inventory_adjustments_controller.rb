class InventoryAdjustmentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @adjustments = current_user.organization.inventory_adjustments
                               .includes(product_batch: :product, user: [])
                               .order(created_at: :desc)
  end

  def new
    load_form_data
  end

  def create
    load_form_data

    batch = current_user.organization.product_batches.find_by(id: params[:product_batch_id])

    if batch.nil?
      flash.now[:alert] = "Please select a valid batch."
      return render :new, status: :unprocessable_entity
    end

    is_commodity = %w[seed oil_cake wanda].include?(batch.product.category.to_s)
    reason       = params[:reason]
    notes        = params[:notes]

    if reason.blank?
      flash.now[:alert] = "Please select a reason."
      return render :new, status: :unprocessable_entity
    end

    # Calculate raw quantity from form inputs
    raw_qty = if is_commodity
      params[:quantity_maund].to_f * 40 + params[:quantity_kg].to_f
    else
      params[:quantity].to_f
    end

    if raw_qty <= 0
      flash.now[:alert] = "Please enter a quantity greater than zero."
      return render :new, status: :unprocessable_entity
    end

    # Supplier return: cannot return more than on hand
    if reason == "supplier_return" && raw_qty > batch.quantity_on_hand
      on_hand = if is_commodity
        m = (batch.quantity_on_hand / 40).to_i
        k = (batch.quantity_on_hand % 40).round(2)
        "#{m} Maund #{k} KG"
      else
        "#{batch.quantity_on_hand.to_i} units"
      end
      flash.now[:alert] = "Return quantity cannot exceed current stock on hand (#{on_hand})."
      return render :new, status: :unprocessable_entity
    end

    # Determine direction — always positive from form, direction inferred from reason
    quantity_changed = case reason
    when "customer_return"  then  raw_qty.abs
    when "audit_correction" then  params[:direction] == "add" ? raw_qty.abs : -raw_qty.abs
    else                         -raw_qty.abs  # damaged, spillage, supplier_return all deduct
    end

    service = Inventory::AdjustStockService.new(
      organization:     current_user.organization,
      user:             current_user,
      product_batch_id: batch.id,
      quantity_changed: quantity_changed,
      reason:           reason,
      notes:            notes
    )

    if service.call
      begin
        post_ledger_adjustment(reason, batch, raw_qty)
      rescue => e
        return redirect_to inventory_adjustments_path,
          alert: "Stock adjusted but ledger posting failed: #{e.message}"
      end
      redirect_to inventory_adjustments_path, notice: "Adjustment recorded successfully."
    else
      flash.now[:alert] = service.errors.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @adjustment = current_user.organization.inventory_adjustments.find(params[:id])
  end

  def update
    @adjustment = current_user.organization.inventory_adjustments.find(params[:id])
    if Inventory::UpdateAdjustmentService.new(@adjustment, adjustment_params).call
      redirect_to inventory_adjustments_path, notice: "Ledger entry updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def reverse
    @adjustment = current_user.organization.inventory_adjustments.find(params[:id])
    if Inventory::ReverseAdjustmentService.new(@adjustment, current_user).call
      redirect_to inventory_adjustments_path, notice: "Adjustment reversed successfully."
    else
      redirect_to inventory_adjustments_path, alert: "Reversal failed."
    end
  end

  private

  def load_form_data
    @suppliers        = current_user.organization.suppliers.order(:name)
    @farmers          = current_user.organization.farmers.order(:full_name)
    @trading_partners = current_user.organization.trading_partners.order(:business_name)
  end

  def post_ledger_adjustment(reason, batch, raw_qty)
    org = current_user.organization

    case reason
    when "customer_return"
      customer_type = params[:customer_type]
      return_value  = params[:return_value].to_f

      if customer_type == "farmer" && params[:farmer_id].present?
        farmer = org.farmers.find(params[:farmer_id])
        cycle  = farmer.active_khata_cycle
        KhataTransaction.create!(
          organization:      org,
          khata_cycle:       cycle,
          entry_type:        :credit,
          amount:            return_value,
          resulting_balance: 0,
          description:       "Customer return: #{batch.product.name} (#{raw_qty} units returned)"
        )
        cycle.recalculate_balances!

      elsif customer_type == "trading_partner" && params[:trading_partner_id].present?
        partner = org.trading_partners.find(params[:trading_partner_id])
        TradingPartnerLedger.create!(
          organization:      org,
          trading_partner:   partner,
          entry_type:        :credit,
          amount:            return_value,
          resulting_balance: 0,
          description:       "Customer return: #{batch.product.name} (#{raw_qty} units returned)"
        )
        partner.recalculate_ledger_balances!
      end

    when "supplier_return"
      supplier      = batch.product.supplier
      return_amount = params[:supplier_return_amount].to_f

      raise ArgumentError, "Please enter a return amount." if return_amount <= 0

      supplier.supplier_ledgers.create!(
        organization:      org,
        entry_type:        :payment,
        amount:            return_amount,
        resulting_balance: 0,
        description:       "Supplier return: #{batch.product.name} returned to #{supplier.name}"
      )
      supplier.recalculate_ledger_balances!
    end
  end

  def adjustment_params
    params.permit(:quantity_changed, :adjustment_reason, :notes)
  end
end
