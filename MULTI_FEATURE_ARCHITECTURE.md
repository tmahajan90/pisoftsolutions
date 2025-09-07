# Multi-Feature SaaS Architecture

## Overview

This document describes the multi-feature SaaS architecture implemented in your Rails application. The architecture allows users to have a single login but access multiple features based on their subscriptions and purchases.

## Architecture Components

### 1. Core Models

#### Feature Model (`app/models/feature.rb`)
- **Purpose**: Defines available features/modules in the system
- **Key Attributes**:
  - `name`: Feature name (e.g., "WhatsApp Marketing")
  - `slug`: URL-friendly identifier
  - `category`: Feature category (communication, analytics, automation, etc.)
  - `status`: active, inactive, coming_soon
  - `pricing_tiers`: JSON array of pricing plans
  - `trial_days`: Number of trial days available
  - `features_list`: Array of feature capabilities
  - `requirements`: Prerequisites for using the feature

#### UserFeature Model (`app/models/user_feature.rb`)
- **Purpose**: Tracks user's access to specific features
- **Key Attributes**:
  - `status`: active, trial, expired, suspended, inactive
  - `trial_used`: Whether user has used trial
  - `expires_at`: When access expires
  - `suspended_at`: When access was suspended

#### Subscription Model (`app/models/subscription.rb`)
- **Purpose**: Manages user subscriptions to features
- **Key Attributes**:
  - `plan_name`: Subscription plan name
  - `price`: Subscription price
  - `billing_cycle`: daily, weekly, monthly, quarterly, yearly
  - `status`: active, inactive, cancelled, suspended
  - `auto_renew`: Whether subscription auto-renews
  - `usage_limit`: Usage limit for the subscription

### 2. Controllers and Services

#### FeaturesController (`app/controllers/features_controller.rb`)
- **Purpose**: Manages feature browsing, subscription, and trial management
- **Key Actions**:
  - `index`: Browse available features
  - `show`: View feature details
  - `subscribe`: Subscribe to a feature
  - `start_trial`: Start trial for a feature
  - `my_features`: View user's subscribed features
  - `dashboard`: Feature usage dashboard

#### SubscriptionService (`app/services/subscription_service.rb`)
- **Purpose**: Handles subscription business logic
- **Key Methods**:
  - `create_subscription`: Create new subscription
  - `start_trial`: Start feature trial
  - `cancel_subscription`: Cancel subscription
  - `upgrade_subscription`: Upgrade subscription plan
  - `process_billing_cycle`: Handle recurring billing

#### FeatureAuthorization Concern (`app/controllers/concerns/feature_authorization.rb`)
- **Purpose**: Provides authorization helpers for feature access
- **Key Methods**:
  - `check_feature_access`: Verify user has access to feature
  - `require_feature_access`: Require feature access
  - `log_feature_usage`: Log feature usage for analytics
  - `check_usage_limits`: Verify usage limits

### 3. Database Schema

#### Features Table
```sql
CREATE TABLE features (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR NOT NULL UNIQUE,
  slug VARCHAR NOT NULL UNIQUE,
  description TEXT NOT NULL,
  category INTEGER NOT NULL DEFAULT 0,
  status INTEGER NOT NULL DEFAULT 0,
  base_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  featured BOOLEAN DEFAULT false,
  trial_days INTEGER,
  icon VARCHAR,
  pricing_tiers TEXT,
  features_list TEXT,
  requirements TEXT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

#### UserFeatures Table
```sql
CREATE TABLE user_features (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  feature_id BIGINT NOT NULL REFERENCES features(id),
  subscription_id BIGINT REFERENCES subscriptions(id),
  status INTEGER NOT NULL DEFAULT 0,
  trial_used BOOLEAN DEFAULT false,
  trial_started_at TIMESTAMP,
  trial_ends_at TIMESTAMP,
  expires_at TIMESTAMP,
  suspended_at TIMESTAMP,
  suspension_reason TEXT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  UNIQUE(user_id, feature_id)
);
```

#### Subscriptions Table
```sql
CREATE TABLE subscriptions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  feature_id BIGINT NOT NULL REFERENCES features(id),
  plan_name VARCHAR NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  billing_cycle INTEGER NOT NULL DEFAULT 2,
  status INTEGER NOT NULL DEFAULT 0,
  auto_renew BOOLEAN DEFAULT true,
  usage_limit INTEGER,
  features TEXT,
  started_at TIMESTAMP,
  last_billing_date TIMESTAMP,
  next_billing_date TIMESTAMP,
  billing_count INTEGER DEFAULT 0,
  cancelled_at TIMESTAMP,
  cancellation_reason TEXT,
  suspended_at TIMESTAMP,
  suspension_reason TEXT,
  effective_date TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

## Usage Examples

### 1. Creating a New Feature

```ruby
# Create a new feature
feature = Feature.create!(
  name: "Email Marketing",
  slug: "email-marketing",
  description: "Send bulk emails and manage email campaigns",
  category: :communication,
  status: :active,
  base_price: 1999.00,
  trial_days: 14,
  pricing_tiers: [
    {
      "name" => "Starter",
      "price" => 1999.00,
      "billing_cycle" => "monthly",
      "usage_limit" => 10000,
      "features" => ["Bulk email", "Contact management"],
      "is_default" => true,
      "active" => true
    }
  ]
)
```

### 2. User Subscribing to a Feature

```ruby
# User subscribes to a feature
user = User.find(1)
feature = Feature.find_by(slug: 'whatsapp-marketing')

subscription_service = SubscriptionService.new(
  user: user,
  feature: feature,
  plan_name: 'Professional'
)

result = subscription_service.create_subscription
if result[:success]
  puts "Subscription created successfully!"
else
  puts "Error: #{result[:message]}"
end
```

### 3. Checking Feature Access in Controller

```ruby
class MyFeatureController < ApplicationController
  include FeatureAuthorization
  
  before_action :require_login
  before_action :set_feature
  before_action :check_feature_access
  
  def index
    # User has access to this feature
    @data = get_feature_data
    log_feature_usage(@feature, 'index_view')
  end
  
  private
  
  def set_feature
    @feature = Feature.find_by(slug: 'my-feature')
  end
  
  def get_required_feature
    @feature
  end
  
  def feature_required?
    true
  end
end
```

### 4. User Starting a Trial

```ruby
# User starts trial for a feature
user = User.find(1)
feature = Feature.find_by(slug: 'analytics-dashboard')

if feature.can_user_trial?(user)
  feature.start_trial_for_user(user)
  puts "Trial started for #{feature.name}!"
else
  puts "Trial not available"
end
```

## Feature Categories

The system supports the following feature categories:

1. **Communication** (0): WhatsApp, SMS, Email marketing
2. **Analytics** (1): Reports, dashboards, insights
3. **Automation** (2): Chatbots, workflows, triggers
4. **CRM** (3): Lead management, customer tracking
5. **E-commerce** (4): Product management, inventory
6. **Productivity** (5): Task management, scheduling
7. **Integration** (6): API, webhooks, third-party

## Pricing Tiers Structure

Each feature can have multiple pricing tiers:

```json
{
  "name": "Professional",
  "price": 2999.00,
  "billing_cycle": "monthly",
  "usage_limit": 5000,
  "features": [
    "Bulk messaging",
    "Advanced analytics",
    "API access"
  ],
  "is_default": true,
  "active": true
}
```

## User Access Levels

1. **Not Purchased**: User has no access to the feature
2. **Trial**: User is using trial version
3. **Active**: User has active subscription
4. **Expired**: User's subscription has expired
5. **Suspended**: User's access has been suspended
6. **Admin Access**: Admin users have access to all features

## Billing and Subscription Management

### Recurring Billing
- Automatic renewal based on billing cycle
- Payment processing through Razorpay
- Failed payment handling and retry logic

### Subscription Management
- Upgrade/downgrade plans
- Cancel subscriptions
- Suspend/reactivate access
- Usage tracking and limits

### Trial Management
- One-time trial per feature per user
- Automatic conversion to paid subscription
- Trial expiration handling

## Security and Authorization

### Feature Access Control
- Role-based access (admin vs regular users)
- Feature-specific permissions
- Usage limit enforcement
- Session-based access tracking

### Data Protection
- User data isolation
- Feature-specific data access
- Audit logging for feature usage
- Secure payment processing

## Monitoring and Analytics

### Usage Tracking
- Feature usage logging
- Performance metrics
- User engagement analytics
- Revenue tracking per feature

### Health Monitoring
- Subscription status monitoring
- Payment failure alerts
- Usage limit warnings
- System performance metrics

## Deployment and Scaling

### Database Considerations
- Proper indexing for performance
- Foreign key constraints
- Data migration strategies
- Backup and recovery

### Performance Optimization
- Caching strategies
- Query optimization
- Background job processing
- CDN integration

## Future Enhancements

### Planned Features
1. **Multi-tenant Architecture**: Support for organizations
2. **Advanced Analytics**: Detailed usage analytics
3. **API Rate Limiting**: Feature-specific rate limits
4. **White-label Support**: Custom branding per feature
5. **Mobile App Integration**: Native mobile apps
6. **Third-party Integrations**: More external service integrations

### Scalability Considerations
1. **Microservices**: Split features into separate services
2. **Event-driven Architecture**: Async communication between features
3. **Caching Layer**: Redis for session and feature data
4. **Load Balancing**: Distribute feature load across servers
5. **Database Sharding**: Partition data by feature or user

## Getting Started

### 1. Run Migrations
```bash
rails db:migrate
```

### 2. Seed Features
```bash
rails db:seed:features
```

### 3. Create Your First Feature Controller
```ruby
class MyFeatureController < ApplicationController
  include FeatureAuthorization
  
  before_action :require_login
  before_action :set_feature
  before_action :check_feature_access
  
  def index
    # Your feature logic here
  end
  
  private
  
  def set_feature
    @feature = Feature.find_by(slug: 'my-feature')
  end
  
  def get_required_feature
    @feature
  end
  
  def feature_required?
    true
  end
end
```

### 4. Add Routes
```ruby
# config/routes.rb
namespace :my_feature do
  get '/', to: 'my_feature#index'
  # Add more routes as needed
end
```

This architecture provides a solid foundation for building a multi-feature SaaS application where users can subscribe to different features based on their needs and budget.
