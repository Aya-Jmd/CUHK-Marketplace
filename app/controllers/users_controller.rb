class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = User.find(params[:id])
    puts "I AM RENDERING PAGE OF USER #{params[:id]}!! NAME IS : #{User.find(params[:id]).email}"
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to user_path(@user), notice: "Profile updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:college_id, :default_location, :latitude, :longitude)
  end
end
