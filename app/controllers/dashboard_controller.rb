class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @organization = current_user.organization

    # Existing
    @unread_alerts       = @organization.inventory_alerts.unread.latest.includes(product_batch: :product)
    @products            = @organization.products.includes(:product_batches, :supplier).order(:name)
    @low_stock_products  = @organization.products.low_stock.includes(:supplier)

    # Khata stats — Farmers
    @total_farmers          = @organization.farmers.count
    @farmers_we_owe         = @organization.farmers.where("current_balance > 0").sum(:current_balance)
    @farmers_owe_us         = @organization.farmers.where("current_balance < 0").sum(:current_balance).abs
    @total_bardaana_with_farmers = @organization.farmers.sum(:bardaana_balance)

    # Khata stats — Trading Partners
    @total_trading_partners     = @organization.trading_partners.count
    @partners_we_owe            = @organization.trading_partners.where("current_balance > 0").sum(:current_balance)
    @partners_owe_us            = @organization.trading_partners.where("current_balance < 0").sum(:current_balance).abs
    @total_bardaana_with_partners = @organization.trading_partners.sum(:bardaana_balance)

    # Khata stats — Crop Stock
    @crops = @organization.crops.order(:name)
    @total_crop_stock_kg = @organization.crops.sum(:quantity_on_hand)
  end
end
