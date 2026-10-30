class AddActivityToChatroomsAndMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :chatrooms, :last_message_at, :datetime
    add_column :messages, :read_at, :datetime
    add_index :messages, %i[chatroom_id read_at]
  end
end
