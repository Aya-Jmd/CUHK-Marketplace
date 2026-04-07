class Admin::SetupsController < Admin::BaseController
  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(setup_params.merge(setup_completed: true))
      bypass_sign_in(@user) # Keeps Devise from logging them out
      redirect_to admin_root_path, notice: "Account secured. Welcome to the Admin Panel."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def setup_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
