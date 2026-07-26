module Admin
  class OrganizationsController < Admin::BaseController
    def index
      @organizations = Organization.order(:name)
    end

    def new
      @organization = Organization.new
      @organization.build_owner
    end

    def create
      @organization = Organization.new(organization_params)

      respond_to do |format|
        if @organization.save
          flash[:notice] = "Organization created successfully."

          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.remove("organization_modal"),

              turbo_stream.append("organizations_table_body",
                                    partial: "admin/organizations/organization",
                                    locals: { organization: @organization }),
              turbo_stream.update("organization_count", Organization.count)
            ]
          end
          format.html { redirect_to admin_root_path }
        else
          @organization.build_owner unless @organization.owner
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def update
      Organization.find(params[:id]).send_reset_password_instructions
    end

    private

    def organization_params
      permitted = params.require(:organization).permit(
        :name,
        :urdu_name,
        :registration_number,
        owner_attributes: [:full_name, :email, :phone]
      )

      if permitted[:owner_attributes].present?
        generated_password = SecureRandom.hex(8)

        permitted[:owner_attributes] = permitted[:owner_attributes].merge(
          password: generated_password,
          password_confirmation: generated_password,
          role: :owner
        )
      end

      permitted
    end
  end
end
