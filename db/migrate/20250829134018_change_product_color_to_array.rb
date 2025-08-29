class ChangeProductColorToArray < ActiveRecord::Migration[7.1]
  def change
    # Change color column from string to array of strings
    change_column :products, :color, :string, array: true, default: [], using: "(string_to_array(color, ','))"
  end
end
