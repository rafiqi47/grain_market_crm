module Sales
  class ProcessSaleService
    attr_reader :errors

    def initialize(organization:, order_params:, items_params:, existing_order: nil)
      @organization = organization
      @order_params = order_params
      @items_params = items_params
      @existing_order = existing_order
      @errors = []
    end

    def call
      ActiveRecord::Base.transaction do
        # Use existing order for updates, or create a new one
        sales_order = @existing_order || @organization.sales_orders.new
        sales_order.assign_attributes(@order_params)

        running_revenue = 0.0
        running_cost = 0.0

        @items_params.each do |item_attr|
          product = @organization.products.find(item_attr[:product_id])
          requested_qty = item_attr[:quantity].to_i
          unit_price = item_attr[:unit_price].to_d

          if item_attr[:product_batch_id].present?
            batch = @organization.product_batches.lock.find(item_attr[:product_batch_id])
            if batch.quantity_on_hand < requested_qty
              raise StandardError, "Insufficient stock in Batch #{batch.batch_number}."
            end
            rev, cost, _ = allocate_from_batch!(sales_order, batch, requested_qty, unit_price)
            running_revenue += rev
            running_cost += cost
          else
            available_batches = @organization.product_batches.lock.active.where(product_id: product.id).order(expiry_date: :asc).to_a
            total_available = available_batches.sum(&:quantity_on_hand)

            if total_available < requested_qty
              raise StandardError, "Insufficient total stock for #{product.name}."
            end

            remaining_to_fulfill = requested_qty
            available_batches.each do |batch|
              break if remaining_to_fulfill <= 0
              if batch.quantity_on_hand > 0
                take_qty = [batch.quantity_on_hand, remaining_to_fulfill].min
                rev, cost, _ = allocate_from_batch!(sales_order, batch, take_qty, unit_price)
                running_revenue += rev
                running_cost += cost
                remaining_to_fulfill -= take_qty
              end
            end
          end
        end

        sales_order.total_revenue = running_revenue
        sales_order.total_cost = running_cost
        sales_order.net_profit = running_revenue - running_cost
        sales_order.save!
        sales_order
      end
    rescue ActiveRecord::RecordInvalid => e
      @errors << e.message
      false
    rescue StandardError => e
      @errors << e.message
      false
    end

    private

    def allocate_from_batch!(sales_order, batch, qty, unit_price)
      batch.update!(quantity_on_hand: batch.quantity_on_hand - qty)
      rev = qty * unit_price
      cost = qty * batch.purchase_price_per_unit
      profit = rev - cost

      sales_order.sales_line_items.build(
        organization: @organization,
        product_id: batch.product_id,
        product_batch_id: batch.id,
        quantity: qty,
        unit_price: unit_price,
        purchase_price_at_sale: batch.purchase_price_per_unit,
        line_revenue: rev,
        line_cost: cost,
        line_profit: profit
      )
      [rev, cost, profit]
    end
  end
end
