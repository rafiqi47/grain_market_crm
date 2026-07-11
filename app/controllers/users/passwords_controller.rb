# app/controllers/users/passwords_controller.rb
class Users::PasswordsController < Devise::PasswordsController
  
  # PUT /resource/password
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      
      # 1. Flash a welcoming activation message
      set_flash_message!(:notice, :password_activated_successfully)
      
      # 2. Automatically sign the manager/owner in using Devise's bypass helper
      if Devise.sign_in_after_reset_password
        # bypass_sign_in keeps the session active without cycling session hooks
        bypass_sign_in(resource, scope: resource_name)
      end
      
      # 3. Redirect to the post-sign-in path (e.g., the manager/owner dashboard)
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      set_minimum_password_length
      respond_with resource
    end
  end
end
