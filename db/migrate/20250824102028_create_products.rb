class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.decimal :original_price
      t.string :category
      t.string :image_url
      t.string :color
      t.string :badge
      t.decimal :rating
      t.integer :stock
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :products, :category
    add_index :products, :active
  end
end
