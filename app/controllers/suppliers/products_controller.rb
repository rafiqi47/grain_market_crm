# app/controllers/suppliers/products_controller.rb
class Suppliers::ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supplier
  before_action :set_product, only: [:show, :edit, :update, :batches_for_adjustment]

  def show
    @product_batches = @product.product_batches.order(created_at: :desc)
  end

  def edit
  end

  def update
    if @product.update(product_params)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Product updated successfully." }
        format.html { redirect_to supplier_path(@supplier), notice: "Product updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def products_for_adjustment
    products = @supplier.products.order(:name)
    render json: {
      products: products.map do |p|
        { id: p.id, name: p.name, urdu_slug: p.slug, category: p.category, unit: p.unit }
      end
    }
  end

  def batches_for_adjustment
    is_commodity = %w[seed oil_cake wanda].include?(@product.category.to_s)
    batches      = @product.product_batches.where("quantity_on_hand > 0").order(created_at: :desc)

    render json: {
      batches: batches.map do |b|
        label = if is_commodity
          m = (b.quantity_on_hand / 40).to_i
          k = (b.quantity_on_hand % 40).round(2)
          "#{@product.name} — #{m}M #{k}KG on hand"
        else
          "#{b.batch_number.presence || 'No batch #'} — #{b.quantity_on_hand.to_i} #{@product.unit} on hand"
        end
        { id: b.id, label: label }
      end
    }
  end

  def quick_create
    @product          = current_organization.products.new(product_params)
    @product.supplier = @supplier

    if @product.save
      render json: {
        success: true,
        product: {
          id:       @product.id,
          name:     @product.name,
          slug:     @product.slug,
          category: @product.category,
          unit:     @product.unit
        }
      }
    else
      render json: {
        success: false,
        errors:  @product.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_supplier
    @supplier = current_organization.suppliers.find(params[:supplier_id])
  end

  def set_product
    @product = @supplier.products.find(params[:id] || params[:product_id])
  end

  def product_params
    params.require(:product).permit(:name, :slug, :category, :sku, :reorder_threshold, :unit)
  end

  def current_organization
    current_user.organization
  end
end
