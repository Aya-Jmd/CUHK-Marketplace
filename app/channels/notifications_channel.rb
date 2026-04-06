class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    # Every user listens to their own personal frequency
    stream_from "notifications_user_#{current_user.id}" if current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is closed
  end
end
