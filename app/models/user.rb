class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :college
  has_many :items
  has_many :messages
  has_many :conversations_as_buyer, class_name: "Conversation", foreign_key: "buyer_id"
  has_many :conversations_as_seller, class_name: "Conversation", foreign_key: "seller_id"
end