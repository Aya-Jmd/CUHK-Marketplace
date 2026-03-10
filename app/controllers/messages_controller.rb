class MessagesController < ApplicationController
  before_action :authenticate_user! # Devise security: must be logged in!

  def create
    @conversation = Conversation.find(params[:conversation_id])
    @message = @conversation.messages.new(message_params)
    @message.user = current_user

    if @message.save
      # Turbo Streams handles the real-time update automatically!
      # We just need to clear the input box for the user who typed it:
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @conversation }
      end
    else
      # If they tried to send an empty message
      redirect_to @conversation, alert: "Message cannot be empty."
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end