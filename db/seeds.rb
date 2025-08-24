# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
Product.destroy_all

# Create products similar to Digi Bulk Marketing shop with INR pricing and multiple validity options
products_data = [
  {
    name: 'WhatsApp Business API',
    description: 'Official WhatsApp Business API for bulk messaging and customer engagement. Send unlimited messages to your customers.',
    price: 2499.00,
    original_price: 4999.00,
    category: 'WhatsApp Solutions',
    image_url: 'fab fa-whatsapp',
    color: 'green',
    badge: 'Popular',
    rating: 4.9,
    stock: 100,
    validity_type: 'months',
    validity_duration: 12,
    validity_price: 2499.00,
    validity_options: [
      { duration: 30, type: 'days', price: 749, label: '30 Days' },
      { duration: 90, type: 'days', price: 1499, label: '3 Months' },
      { duration: 180, type: 'days', price: 1999, label: '6 Months' },
      { duration: 365, type: 'days', price: 2499, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: 3749, label: 'Lifetime' }
    ]
  },
  {
    name: 'Bulk SMS Gateway',
    description: 'High-delivery SMS gateway for bulk messaging campaigns. Reach millions of customers instantly.',
    price: 1499.00,
    original_price: 2999.00,
    category: 'SMS Solutions',
    image_url: 'fas fa-sms',
    color: 'blue',
    badge: 'Best Seller',
    rating: 4.8,
    stock: 150,
    validity_type: 'months',
    validity_duration: 6,
    validity_price: 1499.00,
    validity_options: [
      { duration: 30, type: 'days', price: 449, label: '30 Days' },
      { duration: 90, type: 'days', price: 899, label: '3 Months' },
      { duration: 180, type: 'days', price: 1499, label: '6 Months' },
      { duration: 365, type: 'days', price: 2499, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: 3749, label: 'Lifetime' }
    ]
  },
  {
    name: 'Email Marketing Platform',
    description: 'Professional email marketing software with automation, templates, and analytics.',
    price: 999.00,
    original_price: 1999.00,
    category: 'Email Marketing',
    image_url: 'fas fa-envelope',
    color: 'purple',
    badge: 'Hot',
    rating: 4.7,
    stock: 200,
    validity_type: 'months',
    validity_duration: 12,
    validity_price: 999.00,
    validity_options: [
      { duration: 30, type: 'days', price: 299, label: '30 Days' },
      { duration: 90, type: 'days', price: 599, label: '3 Months' },
      { duration: 180, type: 'days', price: 799, label: '6 Months' },
      { duration: 365, type: 'days', price: 999, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: 1499, label: 'Lifetime' }
    ]
  },
  {
    name: 'Voice Call API',
    description: 'Cloud-based voice calling API for automated calls and notifications.',
    price: 2999.00,
    original_price: 5999.00,
    category: 'Voice Solutions',
    image_url: 'fas fa-phone',
    color: 'red',
    badge: 'New',
    rating: 4.6,
    stock: 75,
    validity_type: 'months',
    validity_duration: 3,
    validity_price: 2999.00,
    validity_options: [
      { duration: 30, type: 'days', price: 899, label: '30 Days' },
      { duration: 90, type: 'days', price: 1799, label: '3 Months' },
      { duration: 180, type: 'days', price: 2999, label: '6 Months' },
      { duration: 365, type: 'days', price: 4999, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: 7499, label: 'Lifetime' }
    ]
  },
  {
    name: 'Lead Generation Tool',
    description: 'Automated lead generation and qualification system for sales teams.',
    price: 1999.00,
    original_price: 3499.00,
    category: 'Lead Generation',
    image_url: 'fas fa-user-plus',
    color: 'indigo',
    badge: 'Trending',
    rating: 4.5,
    stock: 120,
    validity_type: 'months',
    validity_duration: 6,
    validity_price: 1999.00,
    validity_options: [
      { duration: 30, type: 'days', price: 599, label: '30 Days' },
      { duration: 90, type: 'days', price: 1199, label: '3 Months' },
      { duration: 180, type: 'days', price: 1999, label: '6 Months' },
      { duration: 365, type: 'days', price: 3499, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: 5249, label: 'Lifetime' }
    ]
  },
  {
    name: 'Customer Support Chat',
    description: 'Live chat widget for customer support and lead capture.',
    price: 799.00,
    original_price: 1499.00,
    category: 'Customer Support',
    image_url: 'fas fa-comments',
    color: 'teal',
    badge: 'Sale',
    rating: 4.4,
    stock: 300,
    validity_type: 'months',
    validity_duration: 12,
    validity_price: 799.00,
    validity_options: [
      { duration: 30, type: 'days', price: 239, label: '30 Days' },
      { duration: 90, type: 'days', price: 479, label: '3 Months' },
      { duration: 180, type: 'days', price: 639, label: '6 Months' },
      { duration: 365, type: 'days', price: 799, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: 1199, label: 'Lifetime' }
    ]
  },
  {
    name: 'Social Media Scheduler',
    description: 'Schedule and automate posts across all social media platforms.',
    price: 1299.00,
    original_price: 2199.00,
    category: 'Social Media',
    image_url: 'fas fa-share-alt',
    color: 'pink',
    badge: 'Featured',
    rating: 4.3,
    stock: 180,
    validity_type: 'months',
    validity_duration: 6,
    validity_price: 1299.00,
    validity_options: [
      { duration: 30, type: 'days', price: 389, label: '30 Days' },
      { duration: 90, type: 'days', price: 779, label: '3 Months' },
      { duration: 180, type: 'days', price: 1299, label: '6 Months' },
      { duration: 365, type: 'days', price: 2199, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: 3299, label: 'Lifetime' }
    ]
  },
  {
    name: 'Analytics Dashboard',
    description: 'Comprehensive analytics and reporting for all your marketing campaigns.',
    price: 899.00,
    original_price: 1799.00,
    category: 'Analytics',
    image_url: 'fas fa-chart-line',
    color: 'yellow',
    badge: 'Limited Time',
    rating: 4.2,
    stock: 250,
    validity_type: 'months',
    validity_duration: 12,
    validity_price: 899.00,
    validity_options: [
      { duration: 30, type: 'days', price: 269, label: '30 Days' },
      { duration: 90, type: 'days', price: 539, label: '3 Months' },
      { duration: 180, type: 'days', price: 719, label: '6 Months' },
      { duration: 365, type: 'days', price: 899, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: 1349, label: 'Lifetime' }
    ]
  },
  {
    name: 'CRM Integration',
    description: 'Seamless integration with popular CRM systems for lead management.',
    price: 1599.00,
    original_price: 2799.00,
    category: 'CRM Solutions',
    image_url: 'fas fa-users',
    color: 'orange',
    badge: 'Popular',
    rating: 4.1,
    stock: 90,
    validity_type: 'months',
    validity_duration: 6,
    validity_price: 1599.00,
    validity_options: [
      { duration: 30, type: 'days', price: 479, label: '30 Days' },
      { duration: 90, type: 'days', price: 959, label: '3 Months' },
      { duration: 180, type: 'days', price: 1599, label: '6 Months' },
      { duration: 365, type: 'days', price: 2799, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: 4199, label: 'Lifetime' }
    ]
  },
  {
    name: 'API Development Kit',
    description: 'Complete SDK and documentation for custom integrations.',
    price: 2799.00,
    original_price: 4499.00,
    category: 'Development',
    image_url: 'fas fa-code',
    color: 'gray',
    badge: 'New',
    rating: 4.0,
    stock: 60,
    validity_type: 'months',
    validity_duration: 12,
    validity_price: 2799.00,
    validity_options: [
      { duration: 30, type: 'days', price: 839, label: '30 Days' },
      { duration: 90, type: 'days', price: 1679, label: '3 Months' },
      { duration: 180, type: 'days', price: 2239, label: '6 Months' },
      { duration: 365, type: 'days', price: 2799, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: 4199, label: 'Lifetime' }
    ]
  },
  {
    name: 'Multi-Channel Campaign',
    description: 'Unified platform for WhatsApp, SMS, Email, and Voice campaigns.',
    price: 3999.00,
    original_price: 6499.00,
    category: 'Campaign Management',
    image_url: 'fas fa-bullhorn',
    color: 'cyan',
    badge: 'Best Seller',
    rating: 4.8,
    stock: 80,
    validity_type: 'months',
    validity_duration: 12,
    validity_price: 3999.00,
    validity_options: [
      { duration: 30, type: 'days', price: 1199, label: '30 Days' },
      { duration: 90, type: 'days', price: 2399, label: '3 Months' },
      { duration: 180, type: 'days', price: 3199, label: '6 Months' },
      { duration: 365, type: 'days', price: 3999, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: 5999, label: 'Lifetime' }
    ]
  },
  {
    name: 'Template Library',
    description: 'Pre-built templates for WhatsApp, SMS, and Email campaigns.',
    price: 599.00,
    original_price: 1199.00,
    category: 'Templates',
    image_url: 'fas fa-file-alt',
    color: 'lime',
    badge: 'Sale',
    rating: 4.6,
    stock: 500,
    validity_type: 'months',
    validity_duration: 6,
    validity_price: 599.00,
    validity_options: [
      { duration: 30, type: 'days', price: 179, label: '30 Days' },
      { duration: 90, type: 'days', price: 359, label: '3 Months' },
      { duration: 180, type: 'days', price: 599, label: '6 Months' },
      { duration: 365, type: 'days', price: 1199, label: '1 Year' },
      { duration: 0, type: 'lifetime', price: 1799, label: 'Lifetime' }
    ]
  }
]

products_data.each do |product_data|
  Product.create!(product_data)
end

puts "Created #{Product.count} products"

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

offers.each do |offer_attrs|
  Offer.find_or_create_by!(code: offer_attrs[:code]) do |offer|
    offer.assign_attributes(offer_attrs)
  end
end

puts "Created #{Offer.count} offers"
