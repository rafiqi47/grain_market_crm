# app/controllers/suppliers/products_controller.rb
class Suppliers::ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supplier

  def show
    @product = @supplier.products.find(params[:id])
    @product_batches = @product.product_batches.order(created_at: :desc)
  end

  def quick_create
    @product = current_organization.products.new(product_params)
    @product.supplier = @supplier

    if @product.save
      render json: {
        success: true,
        product: {
          id:       @product.id,
          name:     @product.name,
          slug:     @product.slug,
          category: @product.category
        }
      }
    else
      render json: {
        success: false,
        errors: @product.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_supplier
    @supplier = current_organization.suppliers.find(params[:supplier_id])
  end

  def product_params
    params.require(:product).permit(:name, :slug, :category, :sku, :reorder_threshold)
  end

  def current_organization
    current_user.organization
  end
end
