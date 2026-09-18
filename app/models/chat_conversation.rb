class ChatConversation < ApplicationRecord
  belongs_to :user

  has_many :chat_messages,
           dependent: :destroy

  validates :user,
            presence: true
end