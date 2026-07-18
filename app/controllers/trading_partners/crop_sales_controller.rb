# app/controllers/trading_partners/crop_sales_controller.rb
class TradingPartners::CropSalesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trading_partner

  def new
    @crop_sale = @trading_partner.crop_sales.new
  end

  def create
    @crop_sale = @trading_partner.crop_sales.new(crop_sale_params)
    @crop_sale.organization = current_organization
    @crop_sale.crop = current_organization.crops.find(params[:crop_sale][:crop_id])

    if @crop_sale.save
      redirect_to @trading_partner, notice: "Crop sale recorded and posted to ledger."
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    @crop_sale.errors.add(:base, "Could not post to ledger: #{e.message}")
    render :new, status: :unprocessable_entity
  end

  private

  def set_trading_partner
    @trading_partner = current_organization.trading_partners.find(params[:trading_partner_id])
  end

  def crop_sale_params
    params.require(:crop_sale).permit(:sale_date, :weight_maund, :weight_kg_part, :rate, :bardaana_bags_count, :bardaana_owner)
  end

  def current_organization
    current_user.organization
  end
end
