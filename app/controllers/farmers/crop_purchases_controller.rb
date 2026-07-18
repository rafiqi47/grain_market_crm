# app/controllers/farmers/crop_purchases_controller.rb
class Farmers::CropPurchasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_farmer

  def index
    @crop_purchases = @farmer.crop_purchases
                             .includes(:crop)
                             .order(purchase_date: :desc)
  end

  def new
    @crop_purchase = @farmer.crop_purchases.new
  end

  def create
    crop = current_organization.crops.find_by(id: params.dig(:crop_purchase, :crop_id))

    @crop_purchase = @farmer.crop_purchases.new(crop_purchase_params)
    @crop_purchase.organization = current_organization
    @crop_purchase.crop = crop

    if crop.nil?
      @crop_purchase.errors.add(:crop, "must be selected")
      return render :new, status: :unprocessable_entity
    end

    if @crop_purchase.save
      redirect_to @farmer, notice: "Crop purchase recorded and posted to Khata."
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    @crop_purchase.errors.add(:base, "Could not post to Khata: #{e.message}")
    render :new, status: :unprocessable_entity
  end

  private

  def set_farmer
    @farmer = current_organization.farmers.find(params[:farmer_id])
  end

  def crop_purchase_params
    params.require(:crop_purchase).permit(
      :purchase_date, :gross_weight_maund, :gross_weight_kg_part,
      :katt_deduction_maund, :katt_deduction_kg_part, :market_rate,
      :commission_amount, :labor_cost, :bardaana_bags_count, :bardaana_owner
    )
  end

  def current_organization
    current_user.organization
  end
end
