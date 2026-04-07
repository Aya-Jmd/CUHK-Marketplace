class Conversation < ApplicationRecord
  belongs_to :item
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"

  has_many :messages, dependent: :destroy

  validates :buyer_id, uniqueness: { scope: [ :seller_id, :item_id ] }

  scope :for_user, ->(user) { where("buyer_id = :id OR seller_id = :id", id: user.id) }

  def participant?(user)
    user.present? && [ buyer_id, seller_id ].include?(user.id)
  end

  def other_user_for(user)
    user&.id == buyer_id ? seller : buyer
  end

  def last_message
    if association(:messages).loaded?
      messages.max_by(&:created_at)
    else
      messages.order(created_at: :desc).first
    end
  end
end
