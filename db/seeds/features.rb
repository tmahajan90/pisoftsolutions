# Features seed file
# This creates sample features for the multi-feature SaaS application

puts "Creating features..."

# WhatsApp Marketing Feature
whatsapp_feature = Feature.create!(
  name: "WhatsApp Marketing",
  slug: "whatsapp-marketing",
  description: "Send bulk WhatsApp messages, manage contacts, and track campaign performance with our comprehensive WhatsApp marketing solution.",
  category: :communication,
  status: :active,
  base_price: 999.00,
  featured: true,
  trial_days: 7,
  icon: "fab fa-whatsapp",
  pricing_tiers: [
    {
      "name" => "Starter",
      "price" => 999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 1000,
      "features" => ["Bulk messaging", "Contact management", "Basic analytics"],
      "is_default" => true,
      "active" => true
    },
    {
      "name" => "Professional",
      "price" => 1999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 5000,
      "features" => ["Bulk messaging", "Contact management", "Advanced analytics", "Template library", "Scheduled campaigns"],
      "is_default" => false,
      "active" => true
    },
    {
      "name" => "Enterprise",
      "price" => 4999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 20000,
      "features" => ["Bulk messaging", "Contact management", "Advanced analytics", "Template library", "Scheduled campaigns", "API access", "Priority support"],
      "is_default" => false,
      "active" => true
    }
  ],
  features_list: [
    "Bulk WhatsApp messaging",
    "Contact management and segmentation",
    "Campaign analytics and reporting",
    "Message templates",
    "Scheduled campaigns",
    "Delivery status tracking",
    "Contact import/export",
    "API integration"
  ],
  requirements: [
    "WhatsApp Business API access",
    "Valid phone number for verification"
  ]
)

# Analytics Dashboard Feature
analytics_feature = Feature.create!(
  name: "Analytics Dashboard",
  slug: "analytics-dashboard",
  description: "Comprehensive analytics and reporting dashboard to track your marketing campaigns, customer engagement, and business metrics.",
  category: :analytics,
  status: :active,
  base_price: 1499.00,
  featured: true,
  trial_days: 14,
  icon: "fas fa-chart-bar",
  pricing_tiers: [
    {
      "name" => "Basic",
      "price" => 1499.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 10000,
      "features" => ["Basic reports", "Campaign analytics", "Export data"],
      "is_default" => true,
      "active" => true
    },
    {
      "name" => "Advanced",
      "price" => 2999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 50000,
      "features" => ["Advanced reports", "Campaign analytics", "Export data", "Custom dashboards", "Real-time analytics"],
      "is_default" => false,
      "active" => true
    }
  ],
  features_list: [
    "Campaign performance analytics",
    "Customer engagement metrics",
    "Revenue tracking",
    "Custom dashboard creation",
    "Real-time data updates",
    "Export reports to PDF/Excel",
    "Scheduled report delivery",
    "Data visualization charts"
  ],
  requirements: [
    "Active marketing campaigns",
    "Data source integration"
  ]
)

# AI Chatbot Feature
chatbot_feature = Feature.create!(
  name: "AI Chatbot",
  slug: "ai-chatbot",
  description: "Intelligent AI-powered chatbot that can handle customer queries, provide support, and qualify leads automatically.",
  category: :automation,
  status: :active,
  base_price: 2499.00,
  featured: true,
  trial_days: 7,
  icon: "fas fa-robot",
  pricing_tiers: [
    {
      "name" => "Starter",
      "price" => 2499.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 500,
      "features" => ["Basic chatbot", "Pre-built responses", "Email notifications"],
      "is_default" => true,
      "active" => true
    },
    {
      "name" => "Professional",
      "price" => 4999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 2000,
      "features" => ["Advanced chatbot", "Custom training", "Multi-language support", "Lead qualification", "CRM integration"],
      "is_default" => false,
      "active" => true
    }
  ],
  features_list: [
    "AI-powered conversation handling",
    "Natural language processing",
    "Custom response training",
    "Multi-language support",
    "Lead qualification and scoring",
    "CRM integration",
    "Analytics and insights",
    "24/7 customer support"
  ],
  requirements: [
    "WhatsApp Business API",
    "Training data for AI model"
  ]
)

# Lead Management Feature
lead_management_feature = Feature.create!(
  name: "Lead Management",
  slug: "lead-management",
  description: "Comprehensive lead management system to track, nurture, and convert leads into customers with automated workflows.",
  category: :crm,
  status: :active,
  base_price: 1999.00,
  featured: false,
  trial_days: 10,
  icon: "fas fa-users",
  pricing_tiers: [
    {
      "name" => "Basic",
      "price" => 1999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 1000,
      "features" => ["Lead tracking", "Basic automation", "Contact management"],
      "is_default" => true,
      "active" => true
    },
    {
      "name" => "Advanced",
      "price" => 3999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 5000,
      "features" => ["Lead tracking", "Advanced automation", "Contact management", "Pipeline management", "Custom fields"],
      "is_default" => false,
      "active" => true
    }
  ],
  features_list: [
    "Lead capture and tracking",
    "Automated lead nurturing",
    "Pipeline management",
    "Contact segmentation",
    "Custom lead scoring",
    "Email and SMS automation",
    "Integration with marketing tools",
    "Performance analytics"
  ],
  requirements: [
    "Lead generation source",
    "Contact database"
  ]
)

# E-commerce Integration Feature
ecommerce_feature = Feature.create!(
  name: "E-commerce Integration",
  slug: "ecommerce-integration",
  description: "Seamlessly integrate with your e-commerce platform to sync products, orders, and customer data for targeted marketing.",
  category: :ecommerce,
  status: :active,
  base_price: 2999.00,
  featured: false,
  trial_days: 14,
  icon: "fas fa-shopping-cart",
  pricing_tiers: [
    {
      "name" => "Standard",
      "price" => 2999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 10000,
      "features" => ["Product sync", "Order tracking", "Customer data sync"],
      "is_default" => true,
      "active" => true
    },
    {
      "name" => "Premium",
      "price" => 5999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 50000,
      "features" => ["Product sync", "Order tracking", "Customer data sync", "Inventory management", "Automated campaigns"],
      "is_default" => false,
      "active" => true
    }
  ],
  features_list: [
    "Product catalog synchronization",
    "Order tracking and updates",
    "Customer data integration",
    "Inventory management",
    "Automated marketing campaigns",
    "Abandoned cart recovery",
    "Product recommendation engine",
    "Multi-platform support"
  ],
  requirements: [
    "E-commerce platform (Shopify, WooCommerce, etc.)",
    "API access credentials"
  ]
)

# API Integration Feature
api_feature = Feature.create!(
  name: "API Integration",
  slug: "api-integration",
  description: "Powerful REST API to integrate our platform with your existing business systems and create custom workflows.",
  category: :integration,
  status: :active,
  base_price: 3999.00,
  featured: false,
  trial_days: 7,
  icon: "fas fa-plug",
  pricing_tiers: [
    {
      "name" => "Developer",
      "price" => 3999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 10000,
      "features" => ["REST API access", "Webhooks", "Documentation", "Basic support"],
      "is_default" => true,
      "active" => true
    },
    {
      "name" => "Enterprise",
      "price" => 7999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 100000,
      "features" => ["REST API access", "Webhooks", "Documentation", "Priority support", "Custom endpoints", "SLA guarantee"],
      "is_default" => false,
      "active" => true
    }
  ],
  features_list: [
    "RESTful API endpoints",
    "Webhook notifications",
    "Authentication and security",
    "Rate limiting and quotas",
    "Comprehensive documentation",
    "SDK libraries",
    "Sandbox environment",
    "Technical support"
  ],
  requirements: [
    "Technical expertise",
    "Development environment"
  ]
)

# Coming Soon Feature
coming_soon_feature = Feature.create!(
  name: "Advanced Automation",
  slug: "advanced-automation",
  description: "Advanced automation workflows with conditional logic, multi-step processes, and intelligent decision making.",
  category: :automation,
  status: :coming_soon,
  base_price: 4999.00,
  featured: false,
  trial_days: 0,
  icon: "fas fa-cogs",
  pricing_tiers: [
    {
      "name" => "Professional",
      "price" => 4999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 1000,
      "features" => ["Advanced workflows", "Conditional logic", "Multi-step processes"],
      "is_default" => true,
      "active" => true
    }
  ],
  features_list: [
    "Visual workflow builder",
    "Conditional logic and branching",
    "Multi-step automation processes",
    "Integration with external services",
    "Custom triggers and actions",
    "Workflow analytics",
    "A/B testing for workflows",
    "Team collaboration features"
  ],
  requirements: [
    "Business process understanding",
    "Integration requirements"
  ]
)

puts "Created #{Feature.count} features successfully!"
puts "Features created:"
Feature.all.each do |feature|
  puts "- #{feature.name} (#{feature.category.humanize}) - #{feature.status.humanize}"
end
