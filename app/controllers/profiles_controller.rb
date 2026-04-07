# model for RESTful routes management

class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    render "users/show"
  end

  def edit
    @user = current_user
    render "users/edit"
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully"
    else
      render "users/edit", status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:college_id, :default_location, :latitude, :longitude)
  end
end
