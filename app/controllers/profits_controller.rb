# app/controllers/profits_controller.rb
class ProfitsController < ApplicationController
  before_action :authenticate_user!

  def index
    @period = params[:period] || 'today'
    @start_date, @end_date = determine_date_range(@period, params[:start_date], params[:end_date])

    # 1. Base query for orders within organization & timeframe
    orders = current_user.organization.sales_orders.where(placed_at: @start_date.beginning_of_day..@end_date.end_of_day)

    # 2. Global KPI Cards totals
    @total_revenue = orders.sum(:total_revenue)
    @total_cogs    = orders.sum(:total_cost)
    @net_profit    = orders.sum(:net_profit)

    # 3. Itemized Product & Batch Performance Breakdown
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
                          .order('total_prof DESC') # Highest earning items on top

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
