class AddActiveToValidityOptions < ActiveRecord::Migration[7.1]
  def change
    add_column :validity_options, :active, :boolean, default: true, null: false
  end
end
