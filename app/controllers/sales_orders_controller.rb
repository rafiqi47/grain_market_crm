class SalesOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_sales_order, only: [:show, :edit, :update, :destroy]

  def index
    @sales_orders = current_user.organization.sales_orders.order(created_at: :desc)
  end

  def show
  end

  def new
    @sales_order = current_user.organization.sales_orders.new
    @products = current_user.organization.products.includes(:product_batches)
    @farmers = current_user.organization.farmers.order(:full_name)
    @trading_partners = current_user.organization.trading_partners.order(:business_name)
  end

  def create
    @products = current_user.organization.products.includes(:product_batches)
    @farmers = current_user.organization.farmers.order(:full_name)
    @trading_partners = current_user.organization.trading_partners.order(:business_name)

    items_payload = params[:items]&.values&.map { |i| i.slice(:product_id, :quantity, :unit_price, :product_batch_id) }

    customer_type = params[:customer_type].presence || "walk_in"
    farmer_id     = params[:farmer_id].presence
    tp_id         = params[:trading_partner_id].presence

    service = Sales::ProcessSaleService.new(
      organization: current_user.organization,
      order_params: {
        order_number:       "SO-#{SecureRandom.hex(4).upcase}",
        customer_name:      params[:customer_name],
        placed_at:          Time.current,
        customer_type:      customer_type,
        farmer_id:          customer_type == "farmer_customer" ? farmer_id : nil,
        trading_partner_id: customer_type == "trading_partner_customer" ? tp_id : nil
      },
      items_params: items_payload
    )

    if (sales_order = service.call)
      post_to_ledger!(sales_order)
      redirect_to sales_order_path(sales_order), notice: "Order created successfully."
    else
      flash.now[:alert] = service.errors.join(", ")
      @submitted_items = params[:items] || {}
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @products = Product.includes(:product_batches).all
    @farmers = current_user.organization.farmers.order(:full_name)
    @trading_partners = current_user.organization.trading_partners.order(:business_name)
    @line_items = @sales_order.sales_line_items.includes(product_batch: :product)
  end

  def update
    @products = Product.includes(:product_batches).all
    @farmers = current_user.organization.farmers.order(:full_name)
    @trading_partners = current_user.organization.trading_partners.order(:business_name)
    service_error = nil

    ActiveRecord::Base.transaction do
      @sales_order.sales_line_items.each { |item| item.product_batch.increment!(:quantity_on_hand, item.quantity) }
      @sales_order.sales_line_items.destroy_all

      customer_type = params[:customer_type].presence || "walk_in"
      farmer_id     = params[:farmer_id].presence
      tp_id         = params[:trading_partner_id].presence

      items_payload = params[:items]&.values&.map { |i| i.slice(:product_id, :quantity, :unit_price, :product_batch_id) }
      service = Sales::ProcessSaleService.new(
        organization: current_user.organization,
        existing_order: @sales_order,
        order_params: {
          customer_name:      params[:customer_name],
          customer_type:      customer_type,
          farmer_id:          customer_type == "farmer_customer" ? farmer_id : nil,
          trading_partner_id: customer_type == "trading_partner_customer" ? tp_id : nil
        },
        items_params: items_payload
      )

      if service.call
        flash[:notice] = "Order updated successfully."
        redirect_to sales_order_path(@sales_order) and return
      else
        service_error = service.errors.join(", ")
        raise ActiveRecord::Rollback
      end
    end

    @sales_order.reload
    @submitted_items = params[:items] || {}
    @line_items = @sales_order.sales_line_items.includes(product_batch: :product)
    flash.now[:alert] = service_error || "Update failed."
    render :edit, status: :unprocessable_entity
  end

  def destroy
    ActiveRecord::Base.transaction do
      @sales_order.sales_line_items.each do |item|
        item.product_batch.increment!(:quantity_on_hand, item.quantity)
      end
      @sales_order.destroy
    end

    redirect_to sales_orders_path, notice: "Order deleted and inventory levels restored."
  rescue => e
    redirect_to sales_orders_path, alert: "Failed to delete order: #{e.message}"
  end

  private

  def set_sales_order
    @sales_order = current_user.organization.sales_orders.find(params[:id])
  end

  # Posts the sale total as a debit to the farmer's Khata OR
  # the trading partner's ledger, depending on customer_type.
  # Fires after the sale is fully committed so the order ID exists.
  def post_to_ledger!(sales_order)
    if sales_order.farmer_customer? && sales_order.farmer.present?
      cycle = sales_order.farmer.active_khata_cycle
      KhataTransaction.create!(
        organization:      current_user.organization,
        khata_cycle:       cycle,
        entry_type:        :debit,
        amount:            sales_order.total_revenue,
        resulting_balance: 0,
        description:       "Product sale: Order #{sales_order.order_number}",
        sourceable:        sales_order
      )
      cycle.recalculate_balances!

    elsif sales_order.trading_partner_customer? && sales_order.trading_partner.present?
      TradingPartnerLedger.create!(
        organization:      current_user.organization,
        trading_partner:   sales_order.trading_partner,
        entry_type:        :debit,
        amount:            sales_order.total_revenue,
        resulting_balance: 0,
        description:       "Product sale: Order #{sales_order.order_number}",
        sourceable:        sales_order
      )
      sales_order.trading_partner.recalculate_ledger_balances!
    end
    # walk_in: no ledger posting needed
  end
end
