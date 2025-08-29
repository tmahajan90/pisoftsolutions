class ChangeProductColorToSingleString < ActiveRecord::Migration[7.1]
  def up
    # First, add a temporary column to store the single color value
    add_column :products, :color_single, :string, default: 'blue'
    
    # Update the temporary column with the first color from the array
    execute <<-SQL
      UPDATE products 
      SET color_single = CASE 
        WHEN color IS NULL OR array_length(color, 1) IS NULL THEN 'blue'
        ELSE color[1]
      END
    SQL
    
    # Remove the old array column
    remove_column :products, :color
    
    # Rename the new column to color
    rename_column :products, :color_single, :color
  end

  def down
    # Convert back to array
    change_column :products, :color, :string, array: true, default: []
  end
end
