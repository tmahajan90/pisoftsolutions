class AddValidityOptionToOrderItems < ActiveRecord::Migration[7.1]
  def change
    add_reference :order_items, :validity_option, null: true, foreign_key: true
  end
end
