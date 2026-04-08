class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation
  before_action :ensure_participant!

  def create
    @message = @conversation.messages.new(message_params)
    @message.user = current_user

    if @message.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to conversations_path(conversation_id: @conversation.id) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to conversations_path(conversation_id: @conversation.id), alert: "Message cannot be empty." }
      end
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def ensure_participant!
    return if @conversation.visible_to?(current_user)

    redirect_to root_path, alert: "You are not authorized to view this chat."
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
