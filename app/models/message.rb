class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :user

  validates :content, presence: true

  # The Turbo Streams Magic
  after_create_commit -> { broadcast_append_to self.conversation, target: "messages" }
end
