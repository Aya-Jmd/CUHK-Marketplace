class ConversationsController < ApplicationController
  before_action :authenticate_user! # Devise: Must be logged in

  def index
    # Find all chats where the current user is either the buyer or the seller
    @conversations = Conversation.where("buyer_id = ? OR seller_id = ?", current_user.id, current_user.id)
  end

  def show
    @conversation = Conversation.find(params[:id])

    # Security: Kick them out if they don't belong in this chat!
    unless current_user == @conversation.buyer || current_user == @conversation.seller
      redirect_to root_path, alert: "You are not authorized to view this chat."
      return
    end

    @messages = @conversation.messages.order(created_at: :asc)
    @message = Message.new # This creates the empty object for our input form
  end
end
