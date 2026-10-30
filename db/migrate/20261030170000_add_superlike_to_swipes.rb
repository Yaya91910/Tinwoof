class AddSuperlikeToSwipes < ActiveRecord::Migration[7.2]
  def change
    add_column :swipes, :superlike, :boolean, default: false, null: false
    add_index :swipes, %i[user_id superlike updated_at]
  end
end
