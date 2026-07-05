module Admin
  class DashboardController < Admin::BaseController
    def index
      @users = User.all
    end
  end
end
