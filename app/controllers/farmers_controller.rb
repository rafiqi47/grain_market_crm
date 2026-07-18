# app/controllers/farmers_controller.rb
class FarmersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_farmer, only: [:show, :edit, :update]

  def index
    @farmers = current_organization.farmers.order(:full_name)
  end

  def show
    @active_cycle = @farmer.active_khata_cycle
    @closed_cycles = @farmer.khata_cycles.closed.order(closed_at: :desc)
    @transactions = @active_cycle.khata_transactions.latest
  end

  def new
    @farmer = current_organization.farmers.new
  end

  def create
    @farmer = current_organization.farmers.new(farmer_params)

    if @farmer.save
      redirect_to @farmer, notice: "Farmer was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @farmer.update(farmer_params)
      redirect_to @farmer, notice: "Farmer was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_farmer
    @farmer = current_organization.farmers.find(params[:id])
  end

  def farmer_params
    params.require(:farmer).permit(:full_name, :address, :primary_phone, :secondary_phone)
  end

  def current_organization
    current_user.organization
  end
end
