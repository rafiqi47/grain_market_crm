# app/controllers/profits_controller.rb
class ProfitsController < ApplicationController
  before_action :authenticate_user!

  def index
    @period = params[:period] || 'today'
    @start_date, @end_date = determine_date_range(@period, params[:start_date], params[:end_date])

    # Existing — Product sales KPIs
    orders = current_user.organization.sales_orders
                         .where(placed_at: @start_date.beginning_of_day..@end_date.end_of_day)

    @total_revenue = orders.sum(:total_revenue)
    @total_cogs    = orders.sum(:total_cost)
    @net_profit    = orders.sum(:net_profit)

    # Existing — Batch breakdown
    @batch_perfomance = current_user.organization.sales_line_items
                          .joins(:sales_order, :product, :product_batch)
                          .where(sales_orders: { placed_at: @start_date.beginning_of_day..@end_date.end_of_day })
                          .group('products.name', 'products.slug', 'product_batches.batch_number', 'products.category')
                          .select(
                            'products.name AS prod_name',
                            'products.slug AS prod_slug',
                            'products.category AS prod_category',
                            'product_batches.batch_number AS lot_num',
                            'SUM(sales_line_items.quantity) AS total_units_sold',
                            'SUM(sales_line_items.line_revenue) AS total_rev',
                            'SUM(sales_line_items.line_profit) AS total_prof'
                          )
                          .order('total_prof DESC')

    # NEW — Crop profit report
    # Purchases from farmers in the date range (cost side)
    crop_purchases = current_user.organization.crop_purchases
                                 .joins(:crop)
                                 .where(purchase_date: @start_date..@end_date)
                                 .group('crops.id', 'crops.name', 'crops.urdu_slug')
                                 .select(
                                   'crops.id AS crop_id',
                                   'crops.name AS crop_name',
                                   'crops.urdu_slug AS crop_urdu',
                                   'SUM(crop_purchases.net_weight) AS total_purchased_kg',
                                   'SUM(crop_purchases.net_ledger_value) AS total_purchase_cost',
                                   'SUM(crop_purchases.commission_amount) AS total_commission',
                                   'SUM(crop_purchases.labor_cost) AS total_labor'
                                 )

    # Sales to trading partners in the date range (revenue side)
    crop_sales = current_user.organization.crop_sales
                             .joins(:crop)
                             .where(sale_date: @start_date..@end_date)
                             .group('crops.id', 'crops.name')
                             .select(
                               'crops.id AS crop_id',
                               'crops.name AS crop_name',
                               'SUM(crop_sales.weight) AS total_sold_kg',
                               'SUM(crop_sales.total_value) AS total_sale_revenue'
                             )

    # Merge purchases and sales by crop_id into a unified hash
    purchases_by_crop = crop_purchases.index_by(&:crop_id)
    sales_by_crop     = crop_sales.index_by(&:crop_id)
    all_crop_ids      = (purchases_by_crop.keys + sales_by_crop.keys).uniq

    @crop_profit_report = all_crop_ids.map do |crop_id|
      purchase = purchases_by_crop[crop_id]
      sale     = sales_by_crop[crop_id]

      purchased_kg   = purchase&.total_purchased_kg.to_f
      purchase_cost  = purchase&.total_purchase_cost.to_f
      commission     = purchase&.total_commission.to_f
      labor          = purchase&.total_labor.to_f
      sold_kg        = sale&.total_sold_kg.to_f
      sale_revenue   = sale&.total_sale_revenue.to_f
      margin         = sale_revenue - purchase_cost

      avg_buy_rate   = purchased_kg > 0 ? (purchase_cost / (purchased_kg / 40.0)) : 0
      avg_sell_rate  = sold_kg > 0 ? (sale_revenue / (sold_kg / 40.0)) : 0

      {
        crop_id:       crop_id,
        crop_name:     purchase&.crop_name || sale&.crop_name,
        crop_urdu:     purchase&.crop_urdu,
        purchased_kg:  purchased_kg,
        purchase_cost: purchase_cost,
        commission:    commission,
        labor:         labor,
        sold_kg:       sold_kg,
        sale_revenue:  sale_revenue,
        margin:        margin,
        avg_buy_rate:  avg_buy_rate,
        avg_sell_rate: avg_sell_rate
      }
    end.sort_by { |r| -r[:margin] }

    respond_to do |format|
      format.html
    end
  end

  private

  def determine_date_range(period, custom_start, custom_end)
    today = Date.current
    case period
    when 'week'  then [today.beginning_of_week, today.end_of_week]
    when 'month' then [today.beginning_of_month, today.end_of_month]
    when 'custom'
      if custom_start.present? && custom_end.present?
        [Date.parse(custom_start), Date.parse(custom_end)]
      else
        [today, today]
      end
    else
      [today, today]
    end
  rescue ArgumentError
    [today, today]
  end
end
