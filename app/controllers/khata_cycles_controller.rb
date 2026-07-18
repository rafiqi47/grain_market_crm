# app/controllers/khata_cycles_controller.rb
class KhataCyclesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_farmer
  before_action :set_khata_cycle, only: [:show, :close]
  before_action :authorize_closing!, only: :close

  def show
    @transactions = @khata_cycle.khata_transactions.latest
  end

  def close
    @khata_cycle.close!
    redirect_to @farmer, notice: "Khata cycle closed. Balance carried forward if applicable."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to farmer_khata_cycle_path(@farmer, @khata_cycle), alert: "Could not close cycle: #{e.message}"
  end

  private

  def set_farmer
    @farmer = current_organization.farmers.find(params[:farmer_id])
  end

  def set_khata_cycle
    @khata_cycle = @farmer.khata_cycles.find(params[:id])
  end

  # Closing a cycle is a settlement action with real financial consequences —
  # restricting it to owner/super_admin. Remove this before_action if you want
  # managers to close cycles too.
  def authorize_closing!
    return if current_user.owner? || current_user.super_admin?
    redirect_to @farmer, alert: "Only an owner can close a Khata cycle."
  end

  def current_organization
    current_user.organization
  end
end
