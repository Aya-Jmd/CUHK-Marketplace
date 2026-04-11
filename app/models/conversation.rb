class Conversation < ApplicationRecord
  belongs_to :item
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"

  has_many :messages, dependent: :destroy

  validates :buyer_id, uniqueness: { scope: [ :seller_id, :item_id ] }

  scope :for_user, lambda { |user|
    joins("INNER JOIN users buyers_users ON buyers_users.id = conversations.buyer_id")
      .joins("INNER JOIN users sellers_users ON sellers_users.id = conversations.seller_id")
      .where("buyer_id = :id OR seller_id = :id", id: user.id)
      .where("buyers_users.banned_at IS NULL AND sellers_users.banned_at IS NULL")
  }

  def participant?(user)
    user.present? && [ buyer_id, seller_id ].include?(user.id)
  end

  def visible_to?(user)
    participant?(user) && !buyer&.banned? && !seller&.banned?
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

  def participants
    [ buyer, seller ].compact.uniq
  end
end
