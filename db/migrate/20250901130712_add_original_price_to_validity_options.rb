class AddOriginalPriceToValidityOptions < ActiveRecord::Migration[7.1]
  def up
    add_column :validity_options, :original_price, :decimal, precision: 10, scale: 2
    
    # Set original_price to price for existing validity options
    ValidityOption.update_all('original_price = price')
  end

  def down
    remove_column :validity_options, :original_price
  end
end
