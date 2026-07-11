# app/controllers/suppliers_controller.rb
class SuppliersController < ApplicationController
  before_action :set_supplier, only: [:edit, :update]

  def index
    @suppliers = current_user.organization.suppliers.order(name: :asc)
  end

  def new
    @supplier = current_user.organization.suppliers.build
  end

  def create
    @supplier = current_user.organization.suppliers.build(supplier_params)

    if @supplier.save
      respond_to do |format|
        flash.now[:notice] = "Supplier registered successfully!"
        format.turbo_stream
        format.html { redirect_to suppliers_path, notice: "Supplier registered successfully!" }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Rendered inline inside the dynamic modal frame
  end

  def update
    if @supplier.update(supplier_params)
      respond_to do |format|
        flash.now[:notice] = "Supplier data updated successfully!"
        format.turbo_stream
        format.html { redirect_to suppliers_path, notice: "Supplier data updated successfully!" }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_supplier
    @supplier = current_user.organization.suppliers.find(params[:id])
  end

  def supplier_params
    params.require(:supplier).permit(:name, :company_type, :phone, :email)
  end
end
