class Users::RegistrationsController < Devise::RegistrationsController
  def create
    build_resource(sign_up_params)
    apply_signup_location_defaults(resource)
    resource.save
    yield resource if block_given?

    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  private

  def apply_signup_location_defaults(user)
    if user.default_location.present? && (user.latitude.blank? || user.longitude.blank?)
      user.assign_location(user.default_location)
      return
    end

    user.apply_college_default_location
  end
end
