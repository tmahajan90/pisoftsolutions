class WhatsappMarketingController < ApplicationController
  include FeatureAuthorization
  
  before_action :require_login
  before_action :set_whatsapp_feature
  before_action :check_feature_access
  
  def index
    @campaigns = get_user_campaigns
    @contacts = get_user_contacts
    @analytics = get_campaign_analytics
    
    # Log feature usage
    log_feature_usage(@whatsapp_feature, 'dashboard_view')
  end
  
  def campaigns
    @campaigns = get_user_campaigns
    @can_create_campaign = check_usage_limits(@whatsapp_feature)
    
    log_feature_usage(@whatsapp_feature, 'campaigns_view')
  end
  
  def create_campaign
    result = handle_feature_action(@whatsapp_feature, 'create_campaign', campaign_params)
    
    if result[:success]
      redirect_to whatsapp_marketing_campaigns_path, notice: 'Campaign created successfully!'
    else
      redirect_to whatsapp_marketing_campaigns_path, alert: result[:message]
    end
  end
  
  def send_message
    result = handle_feature_action(@whatsapp_feature, 'send_message', message_params)
    
    if result[:success]
      render json: { success: true, message: 'Message sent successfully!' }
    else
      render json: { success: false, message: result[:message] }
    end
  end
  
  def contacts
    @contacts = get_user_contacts
    @can_import_contacts = check_usage_limits(@whatsapp_feature)
    
    log_feature_usage(@whatsapp_feature, 'contacts_view')
  end
  
  def import_contacts
    result = handle_feature_action(@whatsapp_feature, 'import_contacts', import_params)
    
    if result[:success]
      redirect_to whatsapp_marketing_contacts_path, notice: 'Contacts imported successfully!'
    else
      redirect_to whatsapp_marketing_contacts_path, alert: result[:message]
    end
  end
  
  def analytics
    @analytics = get_campaign_analytics
    @usage_stats = get_user_subscription_info(@whatsapp_feature)
    
    log_feature_usage(@whatsapp_feature, 'analytics_view')
  end
  
  def templates
    @templates = get_user_templates
    @can_create_template = check_usage_limits(@whatsapp_feature)
    
    log_feature_usage(@whatsapp_feature, 'templates_view')
  end
  
  def create_template
    result = handle_feature_action(@whatsapp_feature, 'create_template', template_params)
    
    if result[:success]
      redirect_to whatsapp_marketing_templates_path, notice: 'Template created successfully!'
    else
      redirect_to whatsapp_marketing_templates_path, alert: result[:message]
    end
  end
  
  private
  
  def set_whatsapp_feature
    @whatsapp_feature = Feature.find_by(slug: 'whatsapp-marketing')
  end
  
  def get_required_feature
    @whatsapp_feature
  end
  
  def feature_required?
    true
  end
  
  def execute_feature_action(feature, action, params)
    case action
    when 'create_campaign'
      create_campaign_action(params)
    when 'send_message'
      send_message_action(params)
    when 'import_contacts'
      import_contacts_action(params)
    when 'create_template'
      create_template_action(params)
    else
      { success: false, message: 'Unknown action' }
    end
  end
  
  def create_campaign_action(params)
    # Simulate campaign creation
    campaign = {
      id: SecureRandom.uuid,
      name: params[:name],
      message: params[:message],
      contacts_count: params[:contacts_count],
      created_at: Time.current
    }
    
    # Store campaign (in real app, this would be saved to database)
    Rails.cache.write("campaign_#{campaign[:id]}", campaign)
    
    { success: true, campaign: campaign }
  end
  
  def send_message_action(params)
    # Simulate message sending
    message = {
      id: SecureRandom.uuid,
      to: params[:to],
      message: params[:message],
      status: 'sent',
      sent_at: Time.current
    }
    
    # Store message (in real app, this would be saved to database)
    Rails.cache.write("message_#{message[:id]}", message)
    
    { success: true, message: message }
  end
  
  def import_contacts_action(params)
    # Simulate contact import
    contacts_count = params[:contacts_count] || 100
    
    contacts = []
    contacts_count.times do |i|
      contact = {
        id: SecureRandom.uuid,
        name: "Contact #{i + 1}",
        phone: "+91#{rand(1000000000..9999999999)}",
        imported_at: Time.current
      }
      contacts << contact
    end
    
    # Store contacts (in real app, this would be saved to database)
    Rails.cache.write("contacts_#{current_user.id}", contacts)
    
    { success: true, contacts_count: contacts.count }
  end
  
  def create_template_action(params)
    # Simulate template creation
    template = {
      id: SecureRandom.uuid,
      name: params[:name],
      content: params[:content],
      category: params[:category],
      created_at: Time.current
    }
    
    # Store template (in real app, this would be saved to database)
    Rails.cache.write("template_#{template[:id]}", template)
    
    { success: true, template: template }
  end
  
  def get_user_campaigns
    # In real app, this would query the database
    # For demo purposes, return cached data
    campaigns = Rails.cache.read("user_#{current_user.id}_campaigns") || []
    
    # If no campaigns exist, create some sample data
    if campaigns.empty?
      campaigns = [
        {
          id: SecureRandom.uuid,
          name: "Welcome Campaign",
          message: "Welcome to our service!",
          contacts_count: 150,
          sent_count: 120,
          status: "completed",
          created_at: 2.days.ago
        },
        {
          id: SecureRandom.uuid,
          name: "Promotional Campaign",
          message: "Check out our latest offers!",
          contacts_count: 500,
          sent_count: 0,
          status: "draft",
          created_at: 1.day.ago
        }
      ]
      Rails.cache.write("user_#{current_user.id}_campaigns", campaigns)
    end
    
    campaigns
  end
  
  def get_user_contacts
    # In real app, this would query the database
    contacts = Rails.cache.read("contacts_#{current_user.id}") || []
    
    # If no contacts exist, create some sample data
    if contacts.empty?
      contacts = 50.times.map do |i|
        {
          id: SecureRandom.uuid,
          name: "Contact #{i + 1}",
          phone: "+91#{rand(1000000000..9999999999)}",
          status: ["active", "inactive", "unsubscribed"].sample,
          last_contacted: rand(30).days.ago,
          created_at: rand(90).days.ago
        }
      end
      Rails.cache.write("contacts_#{current_user.id}", contacts)
    end
    
    contacts
  end
  
  def get_campaign_analytics
    campaigns = get_user_campaigns
    
    {
      total_campaigns: campaigns.count,
      total_contacts: get_user_contacts.count,
      total_messages_sent: campaigns.sum { |c| c[:sent_count] },
      delivery_rate: 85.5,
      open_rate: 72.3,
      click_rate: 15.8,
      conversion_rate: 8.2
    }
  end
  
  def get_user_templates
    # In real app, this would query the database
    templates = Rails.cache.read("templates_#{current_user.id}") || []
    
    # If no templates exist, create some sample data
    if templates.empty?
      templates = [
        {
          id: SecureRandom.uuid,
          name: "Welcome Message",
          content: "Hi {{name}}, welcome to our service!",
          category: "welcome",
          created_at: 5.days.ago
        },
        {
          id: SecureRandom.uuid,
          name: "Promotional Offer",
          content: "Hi {{name}}, check out our latest offer: {{offer}}",
          category: "promotional",
          created_at: 3.days.ago
        }
      ]
      Rails.cache.write("templates_#{current_user.id}", templates)
    end
    
    templates
  end
  
  def campaign_params
    params.permit(:name, :message, :contacts_count, :schedule_time)
  end
  
  def message_params
    params.permit(:to, :message, :template_id)
  end
  
  def import_params
    params.permit(:file, :contacts_count, :source)
  end
  
  def template_params
    params.permit(:name, :content, :category)
  end
end
