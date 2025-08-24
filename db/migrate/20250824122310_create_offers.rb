class CreateOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :offers do |t|
      t.string :name
      t.text :description
      t.string :discount_type
      t.decimal :discount_value
      t.decimal :minimum_amount
      t.string :code
      t.boolean :active
      t.datetime :valid_from
      t.datetime :valid_until
      t.integer :usage_limit

      t.timestamps
    end
  end
end
