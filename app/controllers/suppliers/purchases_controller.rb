# app/controllers/suppliers/purchases_controller.rb
class Suppliers::PurchasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supplier

  def new
    @products       = @supplier.products.order(:name)
    @submitted_items = []
  end

  def create
    items = params[:items]&.values || []

    if items.empty?
      flash.now[:alert] = "Please add at least one line item."
      @products        = @supplier.products.order(:name)
      @submitted_items = []
      return render :new, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      # ── Calculate grand total ──────────────────────────────────
      total = items.sum do |item|
        case item[:unit].to_s
        when "kg"
          kg = item[:quantity_maund].to_f * 40 + item[:quantity_kg].to_f
          (kg / 40.0) * item[:price_kg].to_f
        when "ml", "gram"
          item[:packet_count].to_f * item[:price_packet].to_f
        else
          item[:quantity].to_f * item[:price_count].to_f
        end
      end

      amount_paid      = params[:amount_paid].to_f
      amount_on_credit = total - amount_paid

      # ── Create PurchaseOrder ───────────────────────────────────
      purchase_order = @supplier.purchase_orders.create!(
        organization:     current_organization,
        invoice_number:   params[:invoice_number].presence,
        transaction_date: params[:transaction_date].presence || Date.current,
        total_amount:     total,
        amount_paid:      amount_paid,
        amount_on_credit: amount_on_credit
      )

      # ── Create batches ─────────────────────────────────────────
      items.each do |item|
        product = current_organization.products.find(item[:product_id])
        unit    = item[:unit].to_s

        batch_attrs = {
          organization:   current_organization,
          purchase_order: purchase_order,
          batch_number:   item[:batch_number].presence,
          manufacture_date: item[:manufacture_date].presence,
          expiry_date:    item[:expiry_date].presence
        }

        case unit
        when "kg"
          kg              = item[:quantity_maund].to_f * 40 + item[:quantity_kg].to_f
          price_per_maund = item[:price_kg].to_f
          batch_attrs.merge!(
            initial_quantity:        kg,
            quantity_on_hand:        kg,
            purchase_price_per_unit: price_per_maund > 0 ? price_per_maund / 40.0 : 0
          )
        when "ml", "gram"
          packet_count     = item[:packet_count].to_f
          package_size     = item[:package_size].to_f
          price_per_packet = item[:price_packet].to_f
          total_qty        = packet_count * package_size
          batch_attrs.merge!(
            initial_quantity:        total_qty,
            quantity_on_hand:        total_qty,
            purchase_price_per_unit: package_size > 0 ? price_per_packet / package_size : 0,
            package_size:            package_size
          )
        else
          qty = item[:quantity].to_f
          batch_attrs.merge!(
            initial_quantity:        qty,
            quantity_on_hand:        qty,
            purchase_price_per_unit: item[:price_count].to_f
          )
        end

        product.product_batches.create!(**batch_attrs)
      end

      # ── Post to supplier ledger ────────────────────────────────
      last_balance = @supplier.supplier_ledgers.chronological.last&.resulting_balance || 0
      new_balance  = last_balance + total

      @supplier.supplier_ledgers.create!(
        organization:      current_organization,
        purchase_order:    purchase_order,
        entry_type:        :purchase,
        amount:            total,
        resulting_balance: new_balance,
        description:       "Bulk purchase#{params[:invoice_number].present? ? " — Invoice #{params[:invoice_number]}" : ""}"
      )

      @supplier.update_column(:current_balance, new_balance)
    end

    redirect_to supplier_path(@supplier),
      notice: "Purchase recorded — #{params[:items]&.keys&.length || 0} items added to inventory."

  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = "Could not save purchase: #{e.message} — #{e.record&.errors&.full_messages&.join(', ')}"
    @products         = @supplier.products.order(:name)
    @submitted_items  = params[:items]&.values || []
    render :new, status: :unprocessable_entity
  rescue => e
    flash.now[:alert] = "Unexpected error: #{e.message}"
    @products         = @supplier.products.order(:name)
    @submitted_items  = params[:items]&.values || []
    render :new, status: :unprocessable_entity
  end

  private

  def set_supplier
    @supplier = current_organization.suppliers.find(params[:supplier_id])
  end

  def current_organization
    current_user.organization
  end
end
