# app/controllers/suppliers/purchases_controller.rb
class Suppliers::PurchasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supplier

  def new
    @products = @supplier.products.order(:name)
    @submitted_items = []
  end

  def create
    items = params[:items]&.values || []

    if items.empty?
      flash.now[:alert] = "Please add at least one line item."
      @products = @supplier.products.order(:name)
      return render :new, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      # Calculate total from line items
      total = items.sum do |item|
        if commodity_category?(item[:category])
          kg              = item[:quantity_maund].to_f * 40 + item[:quantity_kg].to_f
          price_per_maund = item[:price_commodity].to_f
          (kg / 40.0) * price_per_maund
        else
          item[:quantity].to_f * item[:price_non_commodity].to_f
        end
      end

      amount_paid      = params[:amount_paid].to_f
      amount_on_credit = total - amount_paid

      # Create PurchaseOrder
      purchase_order = @supplier.purchase_orders.create!(
        organization:      current_organization,
        invoice_number:    params[:invoice_number].presence,
        transaction_date:  params[:transaction_date].presence || Date.current,
        total_amount:      total,
        amount_paid:       amount_paid,
        amount_on_credit:  amount_on_credit
      )

      # Create batches for each line item
      items.each do |item|
        product = current_organization.products.find(item[:product_id])

        if commodity_category?(item[:category])
          kg              = item[:quantity_maund].to_f * 40 + item[:quantity_kg].to_f
          price_per_maund = item[:price_commodity].to_f
          price_per_kg    = price_per_maund > 0 ? price_per_maund / 40.0 : 0

          product.product_batches.create!(
            organization:            current_organization,
            initial_quantity:        kg,
            quantity_on_hand:        kg,
            purchase_price_per_unit: price_per_kg,
            manufacture_date:        nil,
            expiry_date:             nil,
            batch_number:            nil
          )
        else
          product.product_batches.create!(
            organization:            current_organization,
            batch_number:            item[:batch_number].presence,
            initial_quantity:        item[:quantity].to_f,
            quantity_on_hand:        item[:quantity].to_f,
            purchase_price_per_unit: item[:price_non_commodity].to_f,
            manufacture_date:        item[:manufacture_date].presence,
            expiry_date:             item[:expiry_date].presence
          )
        end
      end

      # Post to supplier ledger
      last_balance = @supplier.supplier_ledgers.order(created_at: :asc, id: :asc).last&.resulting_balance || 0
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

    redirect_to supplier_path(@supplier), notice: "Purchase recorded successfully — #{params[:items]&.keys&.length || 0} items added to inventory."

  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = "Could not save purchase: #{e.message} — #{e.record&.errors&.full_messages&.join(', ')}"
    @products = @supplier.products.order(:name)
    @submitted_items = params[:items]&.values || []
    render :new, status: :unprocessable_entity
  rescue => e
    flash.now[:alert] = "Unexpected error: #{e.message} — #{e.class}"
    @products = @supplier.products.order(:name)
    @submitted_items = params[:items]&.values || []
    render :new, status: :unprocessable_entity
  end

  private

  def set_supplier
    @supplier = current_organization.suppliers.find(params[:supplier_id])
  end

  def commodity_category?(category)
    %w[seed oil_cake wanda].include?(category.to_s)
  end

  def current_organization
    current_user.organization
  end
end
