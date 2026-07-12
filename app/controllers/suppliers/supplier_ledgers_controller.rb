# app/controllers/suppliers/supplier_ledgers_controller.rb
module Suppliers
  class SupplierLedgersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_supplier
    before_action :set_ledger, only: [:edit, :update, :destroy]

    def new
      @ledger = @supplier.supplier_ledgers.build
    end

    def create
      @ledger = @supplier.supplier_ledgers.build(ledger_params.merge(organization_id: current_user.organization.id))
      @ledger.resulting_balance = @supplier.current_balance

      if @ledger.save
        @supplier.recalculate_ledger_balances!
        respond_to do |format|
          format.turbo_stream { flash.now[:notice] = "Ledger voucher added successfully." }
          format.html { redirect_to supplier_path(@supplier), notice: "Ledger voucher added successfully." }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @ledger.update(ledger_params)
        @supplier.recalculate_ledger_balances!
        respond_to do |format|
          format.turbo_stream { flash.now[:notice] = "Ledger transaction updated successfully." }
          format.html { redirect_to supplier_path(@supplier), notice: "Ledger transaction updated successfully." }
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @ledger.destroy
      @supplier.recalculate_ledger_balances!

      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Ledger voucher removed and balances recalculated." }
        format.html { redirect_to supplier_path(@supplier), notice: "Ledger entry removed." }
      end
    end

    private

    def set_supplier
      @supplier = current_user.organization.suppliers.find(params[:supplier_id])
    end

    def set_ledger
      @ledger = @supplier.supplier_ledgers.find(params[:id])
    end

    def ledger_params
      params.require(:supplier_ledger).permit(:entry_type, :amount, :description)
    end
  end
end
