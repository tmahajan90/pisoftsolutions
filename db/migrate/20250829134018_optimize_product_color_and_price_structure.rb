class OptimizeProductColorAndPriceStructure < ActiveRecord::Migration[7.1]
  def up
    # Skip the array conversion and go directly to single string with default
    # This optimizes the color column to be a single string with 'blue' default
    change_column :products, :color, :string, default: 'blue'
    
    # Add original_price column to validity_options
    add_column :validity_options, :original_price, :decimal, precision: 10, scale: 2
    
    # Set original_price to price for existing validity options
    ValidityOption.update_all('original_price = price')
    
    # Migrate existing price data from products to validity options
    Product.find_each do |product|
      if product.validity_options.any?
        # Update existing validity options with original_price from product
        product.validity_options.update_all(original_price: product.original_price || product.price)
      else
        # Create a default validity option if none exist
        product.validity_options.create!(
          duration_type: 'days',
          duration_value: 1,
          price: product.price,
          original_price: product.original_price || product.price,
          label: '1 Day Trial',
          is_default: true,
          sort_order: 0,
          active: true
        )
      end
    end
    
    # Remove price columns from products
    remove_column :products, :price, :decimal
    remove_column :products, :original_price, :decimal
  end

  def down
    # Add price columns back to products
    add_column :products, :price, :decimal, precision: 10, scale: 2
    add_column :products, :original_price, :decimal, precision: 10, scale: 2
    
    # Migrate data back from validity options
    Product.find_each do |product|
      default_option = product.default_validity_option
      if default_option
        product.update_columns(
          price: default_option.price,
          original_price: default_option.original_price || default_option.price
        )
      end
    end
    
    # Remove original_price column from validity_options
    remove_column :validity_options, :original_price
    
    # Revert color column to original state (assuming it was originally a string)
    change_column :products, :color, :string
  end
end
