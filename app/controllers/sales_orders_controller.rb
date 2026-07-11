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
  end

  def create
    @products = current_user.organization.products.includes(:product_batches)
    items_payload = params[:items]&.values&.map { |i| i.slice(:product_id, :quantity, :unit_price, :product_batch_id) }

    service = Sales::ProcessSaleService.new(
      organization: current_user.organization,
      order_params: { order_number: "SO-#{SecureRandom.hex(4).upcase}", customer_name: params[:customer_name], placed_at: Time.current },
      items_params: items_payload
    )

    if (sales_order = service.call)
      redirect_to sales_order_path(sales_order), notice: "Order created successfully."
    else
      flash.now[:alert] = service.errors.join(", ")
      @submitted_items = params[:items] || {}
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @products = Product.includes(:product_batches).all
    @line_items = @sales_order.sales_line_items.includes(product_batch: :product)
  end

  def update
    @products = Product.includes(:product_batches).all
    service_error = nil

    ActiveRecord::Base.transaction do
      @sales_order.sales_line_items.each { |item| item.product_batch.increment!(:quantity_on_hand, item.quantity) }
      @sales_order.sales_line_items.destroy_all

      items_payload = params[:items]&.values&.map { |i| i.slice(:product_id, :quantity, :unit_price, :product_batch_id) }
      service = Sales::ProcessSaleService.new(
        organization: current_user.organization,
        existing_order: @sales_order,
        order_params: { customer_name: params[:customer_name] },
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
      # Revert inventory for each line item
      @sales_order.sales_line_items.each do |item|
        item.product_batch.increment!(:quantity_on_hand, item.quantity)
      end
      
      # Delete the order
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
end
