class MigrateValidityOptionsData < ActiveRecord::Migration[7.1]
  def up
    Product.find_each do |product|
      next if product.validity_options.blank?
      
      # Parse the JSON validity options
      options = product.validity_options
      next unless options.is_a?(Array)
      
      options.each_with_index do |option, index|
        next unless option.is_a?(Hash)
        
        # Create validity option record
        product.validity_options.create!(
          duration_type: option['type'] || option[:type] || 'days',
          duration_value: option['duration'] || option[:duration] || 0,
          price: option['price'] || option[:price] || product.price,
          label: option['label'] || option[:label] || "#{option['duration'] || option[:duration]} #{option['type'] || option[:type]}",
          is_default: index == 0, # First option is default
          sort_order: index
        )
      end
    end
    
    puts "Migrated validity options for #{Product.count} products"
  end
  
  def down
    ValidityOption.destroy_all
  end
end
