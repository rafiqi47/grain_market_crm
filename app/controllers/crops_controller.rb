# app/controllers/crops_controller.rb
class CropsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_crop, only: [:show, :edit, :update]

  def index
    @crops = current_organization.crops.order(:name)
  end

  def show
    @recent_purchases = @crop.crop_purchases.order(created_at: :desc).limit(10)
    @recent_sales = @crop.crop_sales.order(created_at: :desc).limit(10)
  end

  def new
    @crop = current_organization.crops.new
  end

  def create
    @crop = current_organization.crops.new(crop_params)

    if @crop.save
      redirect_to @crop, notice: "Crop was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @crop.update(crop_params)
      redirect_to @crop, notice: "Crop was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_crop
    @crop = current_organization.crops.find(params[:id])
  end

  def crop_params
    params.require(:crop).permit(:name)
  end

  def current_organization
    current_user.organization
  end
end
