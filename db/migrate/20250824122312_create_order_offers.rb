class CreateOrderOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :order_offers do |t|
      t.references :order, null: false, foreign_key: true
      t.references :offer, null: false, foreign_key: true
      t.decimal :discount_amount
      t.datetime :applied_at

      t.timestamps
    end
  end
end
