# model for RESTful routes management

class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @favorite_items = current_user.favorited_items.available
      .includes(:college, :category, :user)
      .with_attached_images
      .order("favorites.created_at DESC")
    preload_favorited_item_ids(@favorite_items)
    render "users/show"
  end

  def edit
    @user = current_user
    render "users/edit"
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to dashboard_path, notice: "Profile updated successfully"
    else
      render "users/edit", status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:college_id, :default_location, :latitude, :longitude)
  end
end
