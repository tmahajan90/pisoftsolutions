class RemoveAvailableColorsTable < ActiveRecord::Migration[7.1]
  def up
    drop_table :available_colors if table_exists?(:available_colors)
  end

  def down
    create_table :available_colors do |t|
      t.string :name
      t.string :value
      t.integer :sort_order
      t.boolean :active
      t.timestamps
    end
  end
end
