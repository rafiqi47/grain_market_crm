# app/controllers/expirations_controller.rb
class ExpirationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @batches = filtered_batches.order(:expiry_date)

    # Summary counts for the filter bar badges
    @expired_count      = base_batches.where("expiry_date < ?", Date.current).count
    @within_7_days      = base_batches.where(expiry_date: Date.current..7.days.from_now.to_date).count
    @within_30_days     = base_batches.where(expiry_date: Date.current..30.days.from_now.to_date).count
  end

  def detail
    @batch = current_organization.product_batches
                                 .includes(product: :supplier)
                                 .find(params[:id])
  end

  private

  def base_batches
    current_organization.product_batches
                        .includes(product: :supplier)
                        .where.not(expiry_date: nil)
                        .where("quantity_on_hand > 0")
  end

  def filtered_batches
    filter = params[:filter]
    from   = params[:from].presence
    to     = params[:to].presence

    case filter
    when "expired"
      base_batches.where("expiry_date < ?", Date.current)
    when "7_days"
      base_batches.where(expiry_date: Date.current..7.days.from_now.to_date)
    when "30_days"
      base_batches.where(expiry_date: Date.current..30.days.from_now.to_date)
    when "custom"
      if from && to
        base_batches.where(expiry_date: Date.parse(from)..Date.parse(to))
      else
        base_batches
      end
    else
      base_batches
    end
  end

  def current_organization
    current_user.organization
  end
end
