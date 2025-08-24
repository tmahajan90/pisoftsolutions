class AddValidityToCartItems < ActiveRecord::Migration[7.1]
  def change
    add_column :cart_items, :validity_type, :string
    add_column :cart_items, :validity_duration, :integer
    add_column :cart_items, :validity_price, :decimal
  end
end
