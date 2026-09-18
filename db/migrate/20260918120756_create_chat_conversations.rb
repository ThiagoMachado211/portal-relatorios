class CreateChatConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_conversations do |t|
      t.references :user,
                   null: false,
                   foreign_key: true,
                   index: true

      t.timestamps
    end

    add_index :chat_conversations,
              [:user_id, :created_at]
  end
end