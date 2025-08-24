class RemoveValidityOptionsFromProducts < ActiveRecord::Migration[7.1]
  def up
    # Only remove if all products have been migrated to the new system
    if ValidityOption.count > 0
      remove_column :products, :validity_options
    end
  end
  
  def down
    add_column :products, :validity_options, :text
  end
end
