class CreateFeatures < ActiveRecord::Migration[7.1]
  def change
    create_table :features do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description, null: false
      t.integer :category, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.decimal :base_price, precision: 10, scale: 2, null: false, default: 0
      t.boolean :featured, default: false
      t.integer :trial_days
      t.string :icon
      t.text :pricing_tiers
      t.text :features_list
      t.text :requirements

      t.timestamps
    end
    
    add_index :features, :slug, unique: true
    add_index :features, :name, unique: true
    add_index :features, :category
    add_index :features, :status
    add_index :features, :featured
  end
end
