module Admin
  class DashboardController < Admin::BaseController
    def index
      # Eager load owner and managers to prevent N+1 queries in the view
      @organizations = Organization.includes(:owner, :managers).order(:name)
    end
  end
end
