class AddMultipleValidityOptionsToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :validity_options, :text
  end
end
