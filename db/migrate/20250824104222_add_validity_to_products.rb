class AddValidityToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :validity_type, :string
    add_column :products, :validity_duration, :integer
    add_column :products, :validity_price, :decimal
  end
end
