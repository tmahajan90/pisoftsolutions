class AddValidityFieldsToOrderItems < ActiveRecord::Migration[7.1]
  def change
    add_column :order_items, :validity_type, :string
    add_column :order_items, :validity_duration, :integer
  end
end
