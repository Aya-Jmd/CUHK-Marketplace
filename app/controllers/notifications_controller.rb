class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    # fetches only unread notifs for index page
    @notifications = current_user.notifications.includes(:actor, :notifiable).where(read_at: nil).order(created_at: :desc)
  end

  def all
    # fetches all notifications
    @notifications = current_user.notifications.includes(:actor, :notifiable).order(created_at: :desc)

  end



  def mark_as_read
    notification = current_user.notifications.find(params[:id])
    notification.update(read_at: Time.current) if notification.read_at.nil?

    # redirects to profile after marking that notif as read.
    redirect_to profile_path
  end


  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    # redirects to same page after marking all notifications as read.
    redirect_to notifications_path
  end
end
