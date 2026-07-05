class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Expose current user role status context directly to the view layout
    @user_role = current_user.role.titleize
  end
end
