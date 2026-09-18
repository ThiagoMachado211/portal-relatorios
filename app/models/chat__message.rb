class ChatMessage < ApplicationRecord
  belongs_to :chat_conversation

  enum :role, {
    user: "user",
    assistant: "assistant"
  }

  validates :role,
            presence: true

  validates :content,
            presence: true
end