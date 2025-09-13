# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Disable automatic validity option creation during seeding to avoid conflicts
Product.skip_default_validity_option_creation = true

# Clear existing data (only if explicitly requested)
# Product.destroy_all
# User.destroy_all

# Create products similar to Digi Bulk Marketing shop with INR pricing and multiple validity options
# products_data = [
#   {
#     name: 'WhatsApp Business API',
#     description: 'Official WhatsApp Business API for bulk messaging and customer engagement. Send unlimited messages to your customers.',
#     category: 'WhatsApp Solutions',
#     image_url: 'fab fa-whatsapp',
#     color: 'green',
#     badge: 'Popular',
#     rating: 4.9,
#     stock: 100,
#     active: true,
#     features: 'Unlimited messaging, Bulk campaigns, Media sharing, Template management, Analytics dashboard, API integration, 24/7 support',
#     validity_options: [
#       { duration: 1, type: 'days', price: 1, original_price: 1, label: '1 Day Trial' },
#       { duration: 30, type: 'days', price: 749, original_price: 1499, label: '30 Days' },
#       { duration: 90, type: 'days', price: 1499, original_price: 2999, label: '3 Months' },
#       { duration: 180, type: 'days', price: 1999, original_price: 3999, label: '6 Months' },
#       { duration: 365, type: 'days', price: 2499, original_price: 4999, label: '1 Year' },
#       { duration: 0, type: 'lifetime', price: 3749, original_price: 7499, label: 'Lifetime' }
#     ]
#   }
# ]

# created_products = 0
# existing_products = 0

# products_data.each do |product_data|
#   validity_options = product_data.delete(:validity_options)
  
#   # Check if product exists
#   existing_product = Product.find_by(name: product_data[:name])
  
#   if existing_product
#     existing_products += 1
#     product = existing_product
#   else
#     # Create new product
#     product = Product.create!(product_data)
#     created_products += 1
#   end
  
#   # Create validity options for the product (only if they don't exist)
#   # First, ensure no existing options are marked as default to avoid conflicts
#   if product.validity_options.exists?
#     product.validity_options.update_all(is_default: false)
#   end
  
#   # Track if we've set a default option for this product
#   default_set = false
  
#   validity_options.each_with_index do |option_data, index|
#     existing_option = product.validity_options.find_by(
#       duration_type: option_data[:type],
#       duration_value: option_data[:duration]
#     )
    
#     unless existing_option
#       # Set the 30-day option (index 1) as default, but only if we haven't set one yet
#       should_be_default = index == 1 && !default_set
      
#       validity_option = product.validity_options.create!(
#         duration_type: option_data[:type],
#         duration_value: option_data[:duration],
#         price: option_data[:price],
#         original_price: option_data[:original_price] || option_data[:price],
#         label: option_data[:label],
#         is_default: should_be_default,
#         sort_order: index,
#         active: true # All options are active by default
#       )
      
#       # Mark that we've set a default option
#       default_set = true if should_be_default
      
#       puts "  Created validity option: #{validity_option.label} - ₹#{validity_option.price} (was ₹#{validity_option.original_price})"
#     else
#       puts "  Found existing validity option: #{existing_option.label}"
#     end
#   end
# end

# if created_products > 0
#   puts "Created #{created_products} new products"
# end
# if existing_products > 0
#   puts "Found #{existing_products} existing products (no changes made)"
# end
# puts "Total products: #{Product.count}"

# Create sample offers
offers = [
  {
    name: "Welcome Discount",
    description: "Get 10% off on your first order",
    discount_type: "percentage",
    discount_value: 10.0,
    minimum_amount: 100.0,
    code: "WELCOME10",
    active: true,
    valid_from: 1.month.ago,
    valid_until: 1.year.from_now,
    usage_limit: 1000
  },
  {
    name: "Flash Sale",
    description: "Save ₹500 on orders above ₹2000",
    discount_type: "fixed",
    discount_value: 500.0,
    minimum_amount: 2000.0,
    code: "FLASH500",
    active: true,
    valid_from: 1.week.ago,
    valid_until: 1.week.from_now,
    usage_limit: 100
  },
  {
    name: "Bulk Purchase",
    description: "Get 15% off on orders above ₹5000",
    discount_type: "percentage",
    discount_value: 15.0,
    minimum_amount: 5000.0,
    code: "BULK15",
    active: true,
    valid_from: 2.weeks.ago,
    valid_until: 6.months.from_now,
    usage_limit: 500
  },
  {
    name: "Student Discount",
    description: "Special 20% discount for students",
    discount_type: "percentage",
    discount_value: 20.0,
    minimum_amount: 50.0,
    code: "STUDENT20",
    active: true,
    valid_from: 1.month.ago,
    valid_until: 1.year.from_now,
    usage_limit: 200
  }
]

created_offers = 0
existing_offers = 0

offers.each do |offer_attrs|
  existing_offer = Offer.find_by(code: offer_attrs[:code])
  
  if existing_offer
    existing_offers += 1
  else
    Offer.create!(offer_attrs)
    created_offers += 1
  end
end

if created_offers > 0
  puts "Created #{created_offers} new offers"
end
if existing_offers > 0
  puts "Found #{existing_offers} existing offers (no changes made)"
end
puts "Total offers: #{Offer.count}"

# Create admin user
existing_admin = User.find_by(email: 'tarun@pisoftsolutions.in')
if existing_admin
  admin_user = existing_admin
  puts "Found existing admin user: #{admin_user.email}"
else
  admin_user = User.create!(
    name: 'Admin User',
    email: 'tarun@pisoftsolutions.in',
    password: 'ox4ymoro',
    password_confirmation: 'ox4ymoro',
    phone: '+91-9988915210',
    role: 'admin'
  )
  puts "Created new admin user: #{admin_user.email}"
end

existing_admin = User.find_by(email: 'vaneet@pisoftsolutions.in')
if existing_admin
  admin_user = existing_admin
  puts "Found existing admin user: #{admin_user.email}"
else
  admin_user = User.create!(
    name: 'Admin User',
    email: 'vaneet@pisoftsolutions.in',
    password: 'ox4ymoro',
    password_confirmation: 'ox4ymoro',
    phone: '+91-9988915211',
    role: 'admin'
  )
  puts "Created new admin user: #{admin_user.email}"
end

# Create demo user
existing_demo = User.find_by(email: 'demo@pisoftsolutions.in')
if existing_demo
  demo_user = existing_demo
  puts "Found existing demo user: #{demo_user.email}"
else
  demo_user = User.create!(
    name: 'Demo User',
    email: 'demo@pisoftsolutions.in',
    password: 'demo123',
    password_confirmation: 'demo123',
    phone: '+91-9876543211',
    role: 'user'
  )
  puts "Created new demo user: #{demo_user.email}"
end

# Re-enable automatic validity option creation
Product.skip_default_validity_option_creation = false

# Load features
puts "\nLoading features..."
load Rails.root.join('db', 'seeds', 'features.rb')

puts "✅ Setup complete!"
