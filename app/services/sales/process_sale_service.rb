# app/services/sales/process_sale_service.rb
module Sales
  class ProcessSaleService
    attr_reader :errors

    def initialize(organization:, order_params:, items_params:, existing_order: nil)
      @organization   = organization
      @order_params   = order_params
      @items_params   = items_params
      @existing_order = existing_order
      @errors         = []
    end

    def call
      ActiveRecord::Base.transaction do
        sales_order = @existing_order || @organization.sales_orders.new
        sales_order.assign_attributes(@order_params)

        running_revenue = 0.0
        running_cost    = 0.0

        @items_params.each do |item_attr|
          product       = @organization.products.find(item_attr[:product_id])
          is_packet     = %w[ml gram].include?(product.unit.to_s)
          requested_qty = item_attr[:quantity].to_i       # bottles/packets OR bags/pieces/kg
          package_size  = item_attr[:package_size].to_f   # ml or g per bottle/packet (0 for non-packet)
          unit_price    = item_attr[:unit_price].to_d     # price per bottle/packet or per bag/piece

          # For ml/gram: stock is stored in base units (ml/g), need to deduct qty × package_size
          actual_deduction = is_packet ? (requested_qty * package_size).to_f : requested_qty.to_f

          if item_attr[:product_batch_id].present?
            # ── Specific batch selected ────────────────────────────────
            batch = @organization.product_batches.lock.find(item_attr[:product_batch_id])

            if batch.quantity_on_hand < actual_deduction
              raise StandardError,
                "Insufficient stock in batch #{batch.batch_number.presence || 'no batch #'}. " \
                "Need #{actual_deduction} #{product.unit}, have #{batch.quantity_on_hand}."
            end

            rev, cost, _ = allocate_from_batch!(
              sales_order, batch, requested_qty, unit_price, package_size, is_packet
            )
            running_revenue += rev
            running_cost    += cost

          else
            # ── FIFO ────────────────────────────────────────────────────
            available_batches = if is_packet && package_size > 0
              # Filter by package size so we only FIFO from same-size batches
              @organization.product_batches.lock.active
                           .where(product_id: product.id, package_size: package_size)
                           .order(expiry_date: :asc).to_a
            else
              @organization.product_batches.lock.active
                           .where(product_id: product.id)
                           .order(expiry_date: :asc).to_a
            end

            total_available = available_batches.sum(&:quantity_on_hand)

            if total_available < actual_deduction
              label = is_packet ? "#{package_size.to_i}#{product.unit} #{product.name}" : product.name
              raise StandardError,
                "Insufficient total stock for #{label}. " \
                "Need #{actual_deduction} #{product.unit}, have #{total_available}."
            end

            if is_packet
              # FIFO in packets (bottles) — track remaining as packet count
              remaining_packets = requested_qty
              available_batches.each do |batch|
                break if remaining_packets <= 0
                ps = batch.package_size.to_f
                next if ps <= 0

                packets_in_batch = (batch.quantity_on_hand / ps).floor
                take_packets     = [packets_in_batch, remaining_packets].min
                next if take_packets <= 0

                rev, cost, _ = allocate_from_batch!(
                  sales_order, batch, take_packets, unit_price, ps, true
                )
                running_revenue   += rev
                running_cost      += cost
                remaining_packets -= take_packets
              end

            else
              # FIFO in base units (bags/pieces/kg)
              remaining = actual_deduction
              available_batches.each do |batch|
                break if remaining <= 0
                if batch.quantity_on_hand > 0
                  take_qty = [batch.quantity_on_hand, remaining].min
                  rev, cost, _ = allocate_from_batch!(
                    sales_order, batch, take_qty, unit_price, 0, false
                  )
                  running_revenue += rev
                  running_cost    += cost
                  remaining       -= take_qty
                end
              end
            end
          end
        end

        sales_order.total_revenue = running_revenue
        sales_order.total_cost    = running_cost
        sales_order.net_profit    = running_revenue - running_cost
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

    # qty       = bottles/packets for ml/gram, OR bags/pieces/kg for others
    # unit_price = price per bottle/packet or per bag/piece
    # package_size = ml/g per bottle (0 for non-packet products)
    def allocate_from_batch!(sales_order, batch, qty, unit_price, package_size, is_packet)
      base_units_to_deduct = is_packet ? qty * package_size : qty

      batch.update!(quantity_on_hand: batch.quantity_on_hand - base_units_to_deduct)

      # Cost per bottle/packet or per bag/piece
      cost_per_unit = is_packet \
        ? (batch.purchase_price_per_unit * package_size)
        : batch.purchase_price_per_unit

      rev    = qty * unit_price
      cost   = qty * cost_per_unit
      profit = rev - cost

      sales_order.sales_line_items.build(
        organization:           @organization,
        product_id:             batch.product_id,
        product_batch_id:       batch.id,
        quantity:               qty,           # bottles/packets or bags/pieces — NOT raw ml/g
        unit_price:             unit_price,    # per bottle/packet or per bag/piece
        purchase_price_at_sale: cost_per_unit, # cost per bottle/packet or per bag/piece
        line_revenue:           rev,
        line_cost:              cost,
        line_profit:            profit
      )
      [rev, cost, profit]
    end
  end
end
