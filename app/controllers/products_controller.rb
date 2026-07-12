class ProductsController < ApplicationController
  before_action :set_product, only: [:edit, :update, :destroy]

  def index
    @products = current_user.organization.products.includes(:supplier).order(name: :asc)
  end

  def new
    @product = current_user.organization.products.build
  end

  def create
    @product = current_user.organization.products.build(product_params)

    if @product.save
      respond_to do |format|
        flash.now[:notice] = "Product cataloged successfully!"
        format.turbo_stream
        format.html { redirect_to products_path, notice: "Product cataloged successfully!" }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      respond_to do |format|
        flash.now[:notice] = "Product updated successfully!"
        format.turbo_stream
        format.html { redirect_to products_path, notice: "Product updated successfully!" }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("flash-container", render_to_string(partial: "layouts/flash")),
          turbo_stream.update("products_catalog_table", 
            render_to_string(partial: "table", locals: { products: current_user.organization.products.includes(:supplier).order(name: :asc) })
          )
        ]
      end
      format.html { redirect_to products_path, notice: "Product deleted." }
    end
  end

  private

  def set_product
    @product = current_user.organization.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :sku, :category, :supplier_id, :reorder_threshold)
  end
end
