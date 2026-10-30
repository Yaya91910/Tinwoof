class CreateSwipes < ActiveRecord::Migration[7.0]
  def change
    create_table :swipes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :dog, null: false, foreign_key: true
      t.boolean :liked, null: false
      t.timestamps
    end
    add_index :swipes, %i[user_id dog_id], unique: true
  end
end
