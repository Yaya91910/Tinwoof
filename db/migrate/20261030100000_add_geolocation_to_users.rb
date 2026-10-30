class AddGeolocationToUsers < ActiveRecord::Migration[7.0]
  def change
    change_table :users, bulk: true do |t|
      t.float :latitude
      t.float :longitude
      t.datetime :located_at
      t.integer :search_radius_km, default: 25, null: false
      t.text :bio
    end
    add_index :users, %i[latitude longitude]

    # IP-based tracking is replaced by opt-in browser geolocation.
    remove_column :users, :ip, :string
    remove_column :users, :location, :string
  end
end
