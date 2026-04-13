class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: :show
  before_action :ensure_participant!, only: :show

  def index
    load_inbox
  end

  def show
    redirect_to conversations_path(conversation_id: @conversation.id)
  end

  def create
    @item = Item.find(params[:item_id])

    unless @item.visible_to?(current_user)
      redirect_to items_path, alert: "This conversation is no longer available."
      return
    end

    if @item.user == current_user
      redirect_to @item, alert: "You cannot start a conversation on your own item."
      return
    end

    if @item.removed? || @item.user.banned?
      redirect_to items_path, alert: "This conversation is no longer available."
      return
    end

    content = params.dig(:message, :content).to_s.strip
    if content.blank?
      redirect_to @item, alert: "Message cannot be empty."
      return
    end

    # Reuse the existing thread for the buyer/item/seller trio to keep negotiation history in one place.
    @conversation = Conversation.find_or_create_by(item: @item, buyer: current_user, seller: @item.user)
    @message = @conversation.messages.build(user: current_user, content: content)

    if @message.save
      redirect_to conversations_path(conversation_id: @conversation.id), notice: "Conversation ready."
    else
      redirect_to @item, alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def load_inbox
    @conversations = Conversation
      .for_user(current_user)
      .includes(:item, :buyer, :seller, messages: :user)
      .order(updated_at: :desc)

    @current_conversation = if params[:conversation_id].present?
      @conversations.find { |conversation| conversation.id == params[:conversation_id].to_i } || @conversations.first
    else
      @conversations.first
    end

    @messages = @current_conversation ? @current_conversation.messages.sort_by(&:created_at) : []
    @current_offer = current_offer_for(@current_conversation)
    @message = Message.new
  end

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end

  def ensure_participant!
    return if @conversation.visible_to?(current_user)

    redirect_to root_path, alert: "You are not authorized to view this chat."
  end

  def current_offer_for(conversation)
    return unless conversation.present?

    Offer.not_declined.find_by(
      item: conversation.item,
      buyer: conversation.buyer,
      seller: conversation.seller
    )
  end
end
