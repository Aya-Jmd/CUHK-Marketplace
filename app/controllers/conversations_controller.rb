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
    # finds item from which the conversation was started
    @item = Item.find(params[:item_id])

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

    # msg not blank, user is not seller ==> we can create conversation OR if convo with this seller and this item exists, then add new msg
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
    # from Convrsation table, ldads every conversation instances that include the current user (is either a seller or buyer)
    @conversations = Conversation
      .for_user(current_user)
      .includes(:item, :buyer, :seller, messages: :user) # loads for each item the following info, and with each messages loads its attached user
      .order(updated_at: :desc) # sorts conversations, 1st is most recently updated

    # current conversation is either the one specified by conversation_id or the most recent one
    @current_conversation = if params[:conversation_id].present?
      @conversations.find { |conversation| conversation.id == params[:conversation_id].to_i } || @conversations.first # tries getting convo with id, defaults to most recent one
    else
      @conversations.first
    end


    # messages
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

    Offer.find_by(
      item: conversation.item,
      buyer: conversation.buyer,
      seller: conversation.seller
    )
  end
end
