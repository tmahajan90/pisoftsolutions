class AddFeaturesToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :features, :text
  end
end
