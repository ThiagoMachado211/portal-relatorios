class CreateChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_messages do |t|
      t.references :chat_conversation,
                   null: false,
                   foreign_key: true,
                   index: true

      t.string :role,
               null: false

      t.text :content,
             null: false

      t.timestamps
    end

    add_index :chat_messages,
              [:chat_conversation_id, :created_at]
  end
end