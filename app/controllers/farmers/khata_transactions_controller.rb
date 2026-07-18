# app/controllers/farmers/khata_transactions_controller.rb
class Farmers::KhataTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_farmer
  before_action :set_cycle
  before_action :set_transaction, only: [:edit, :update, :destroy]

  def new
    @transaction = @cycle.khata_transactions.new
  end

  def create
    @transaction = @cycle.khata_transactions.new(transaction_params)
    @transaction.organization = current_organization
    @transaction.resulting_balance = 0
    @transaction.bardaana_credit ||= 0
    @transaction.bardaana_debit  ||= 0

    if @transaction.save
      @cycle.recalculate_balances!
      redirect_to farmer_path(@farmer), notice: "Entry added and balances recalculated."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @transaction.assign_attributes(transaction_params)
    @transaction.bardaana_credit ||= 0
    @transaction.bardaana_debit  ||= 0

    if @transaction.save
      @cycle.recalculate_balances!
      redirect_to farmer_path(@farmer), notice: "Transaction updated and balances recalculated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy!
    @cycle.recalculate_balances!
    redirect_to farmer_path(@farmer), notice: "Transaction deleted and balances recalculated."
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to farmer_path(@farmer), alert: "Could not delete: #{e.message}"
  end

  private

  def set_farmer
    @farmer = current_organization.farmers.find(params[:farmer_id])
  end

  def set_cycle
    @cycle = @farmer.khata_cycles.find(params[:khata_cycle_id])
  end

  def set_transaction
    @transaction = @cycle.khata_transactions.find(params[:id])
  end

  def transaction_params
    params.require(:khata_transaction).permit(
      :entry_type, :amount, :bardaana_credit, :bardaana_debit, :description
    )
  end

  def current_organization
    current_user.organization
  end
end
