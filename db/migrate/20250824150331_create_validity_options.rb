class CreateValidityOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :validity_options do |t|
      t.references :product, null: false, foreign_key: true
      t.string :duration_type, null: false
      t.integer :duration_value, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :label, null: false
      t.boolean :is_default, default: false
      t.integer :sort_order, default: 0
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :validity_options, [:product_id, :sort_order]
    add_index :validity_options, [:product_id, :is_default]
    add_index :validity_options, :active
  end
end
