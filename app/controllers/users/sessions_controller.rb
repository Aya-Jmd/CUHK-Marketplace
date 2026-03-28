class Users::SessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate(auth_options)

    if resource
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      self.resource = resource_class.new(sign_in_params.slice(*resource_class.authentication_keys))
      clean_up_passwords(resource)
      flash.now[:alert] = failed_sign_in_message

      render :new, status: :unprocessable_entity
    end
  end

  private

  def failed_sign_in_message
    authentication_key = resource_class.authentication_keys.first
    submitted_login = sign_in_params[authentication_key]

    return default_invalid_sign_in_message unless submitted_login.present?

    existing_user = resource_class.find_for_database_authentication(authentication_key => submitted_login)

    existing_user.present? ? "Wrong password" : default_invalid_sign_in_message
  end

  def default_invalid_sign_in_message
    I18n.t("devise.failure.invalid", authentication_keys: resource_class.authentication_keys.join("/"))
  end
end
