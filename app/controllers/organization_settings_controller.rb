# app/controllers/organization_settings_controller.rb
class OrganizationSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_owner!

  def edit
    @organization = current_user.organization
  end

  def update
    @organization = current_user.organization

    if @organization.update(organization_params)
      redirect_to edit_organization_settings_path, notice: "Organization settings updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def authorize_owner!
    unless current_user.owner? || current_user.super_admin?
      redirect_to dashboard_path, alert: "Not authorized."
    end
  end

  def organization_params
    params.require(:organization).permit(:urdu_name)
  end
end
