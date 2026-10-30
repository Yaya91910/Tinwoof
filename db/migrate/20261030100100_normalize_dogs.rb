class NormalizeDogs < ActiveRecord::Migration[7.0]
  def up
    rename_column :dogs, :race, :breed
    execute "UPDATE dogs SET gender = LOWER(gender)"

    change_column :dogs, :age, :integer, using: "NULLIF(regexp_replace(age, '\\D', '', 'g'), '')::integer"
    change_column :dogs, :height, :integer, using: "NULLIF(regexp_replace(height, '\\D', '', 'g'), '')::integer"
    rename_column :dogs, :height, :height_cm

    add_column :dogs, :traits, :json, default: [], null: false
    add_index :dogs, %i[latitude longitude]
  end

  def down
    remove_index :dogs, %i[latitude longitude]
    remove_column :dogs, :traits
    rename_column :dogs, :height_cm, :height
    change_column :dogs, :height, :string
    change_column :dogs, :age, :string
    execute "UPDATE dogs SET gender = INITCAP(gender)"
    rename_column :dogs, :breed, :race
  end
end
