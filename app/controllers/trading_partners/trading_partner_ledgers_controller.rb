# app/controllers/trading_partners/trading_partner_ledgers_controller.rb
class TradingPartners::TradingPartnerLedgersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trading_partner
  before_action :set_ledger_entry, only: [:edit, :update, :destroy]

  def new
    @ledger_entry = @trading_partner.trading_partner_ledgers.new
  end

  def create
    @ledger_entry = @trading_partner.trading_partner_ledgers.new(ledger_params)
    @ledger_entry.organization = current_organization
    @ledger_entry.resulting_balance = 0
    @ledger_entry.bardaana_credit ||= 0
    @ledger_entry.bardaana_debit  ||= 0

    ActiveRecord::Base.transaction do
      @ledger_entry.save!
      @trading_partner.recalculate_ledger_balances!
    end

    redirect_to @trading_partner, notice: "Ledger entry recorded."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    @ledger_entry.assign_attributes(ledger_params)
    @ledger_entry.bardaana_credit ||= 0
    @ledger_entry.bardaana_debit  ||= 0

    ActiveRecord::Base.transaction do
      @ledger_entry.save!
      @trading_partner.recalculate_ledger_balances!
    end

    redirect_to @trading_partner, notice: "Ledger entry updated."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def destroy
    ActiveRecord::Base.transaction do
      @ledger_entry.destroy!
      @trading_partner.recalculate_ledger_balances!
    end

    redirect_to @trading_partner, notice: "Ledger entry removed."
  end

  private

  def set_trading_partner
    @trading_partner = current_organization.trading_partners.find(params[:trading_partner_id])
  end

  def set_ledger_entry
    @ledger_entry = @trading_partner.trading_partner_ledgers.find(params[:id])
  end

  def ledger_params
    params.require(:trading_partner_ledger).permit(:entry_type, :amount, :bardaana_credit, :bardaana_debit, :description)
  end

  def current_organization
    current_user.organization
  end
end
