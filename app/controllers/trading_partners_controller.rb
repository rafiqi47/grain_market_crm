# app/controllers/trading_partners_controller.rb
class TradingPartnersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trading_partner, only: [:show, :edit, :update]

  def index
    @trading_partners = current_organization.trading_partners.order(:business_name)
  end

  def show
    @ledger_entries = @trading_partner.trading_partner_ledgers.latest
  end

  def new
    @trading_partner = current_organization.trading_partners.new
  end

  def create
    @trading_partner = current_organization.trading_partners.new(trading_partner_params)

    if @trading_partner.save
      redirect_to @trading_partner, notice: "Trading partner was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @trading_partner.update(trading_partner_params)
      redirect_to @trading_partner, notice: "Trading partner was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def statement
    @trading_partner = current_organization.trading_partners.find(params[:id])
    @ledger_entries = @trading_partner.trading_partner_ledgers.chronological
    @sales_orders = @trading_partner.sales_orders.order(placed_at: :desc)
    @crop_sales = @trading_partner.crop_sales.includes(:crop).order(sale_date: :desc)

    render layout: "print"
  end

  private

  def set_trading_partner
    @trading_partner = current_organization.trading_partners.find(params[:id])
  end

  def trading_partner_params
    params.require(:trading_partner).permit(:business_name, :urdu_name, :contact_person, :address, :primary_phone, :secondary_phone)
  end

  def current_organization
    current_user.organization
  end
end
