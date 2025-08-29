class Product < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :destroy
  has_many :validity_options, dependent: :destroy
  has_many :trial_usages, dependent: :destroy
  
  # Class-level flag to disable automatic validity option creation during seeding
  class_attribute :skip_default_validity_option_creation, default: false
  
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :in_stock, -> { where('stock > 0') }
  scope :by_category, ->(category) { where(category: category) }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  
  # Validity types
  VALIDITY_TYPES = ['days', 'months', 'years'].freeze
  
  # Accept nested attributes for validity options
  accepts_nested_attributes_for :validity_options, allow_destroy: true, reject_if: :all_blank
  
  # Callback to ensure only one default validity option
  after_save :ensure_single_default_validity_option
  
  # Serialize validity options (for backward compatibility during migration)
  serialize :validity_options, coder: JSON
  
  # Serialize features as JSON array
  serialize :features, coder: JSON, default: []
  
  # Ensure features is always an array
  before_save :ensure_features_array
  
  # Ensure at least one validity option exists
  after_save :ensure_default_validity_option
  
  # Override features= to ensure proper array handling
  def features=(value)
    Rails.logger.debug "Product#features= called with: #{value.inspect} (class: #{value.class})"
    
    if value.is_a?(Array)
      # Filter out empty strings and ensure unique values
      cleaned_features = value.reject(&:blank?).uniq
      Rails.logger.debug "Setting features to cleaned array: #{cleaned_features.inspect}"
      super(cleaned_features)
    elsif value.is_a?(String)
      # Handle case where value might be a JSON string
      begin
        parsed = JSON.parse(value)
        final_value = parsed.is_a?(Array) ? parsed : [value]
        Rails.logger.debug "Parsed JSON string, setting features to: #{final_value.inspect}"
        super(final_value)
      rescue JSON::ParserError
        Rails.logger.debug "JSON parse failed, setting features to: [#{value}]"
        super([value])
      end
    else
      Rails.logger.debug "Setting features to: #{value.inspect}"
      super(value)
    end
  end
  
  def discount_percentage
    return 0 if original_price.nil? || original_price <= price
    ((original_price - price) / original_price * 100).round
  end
  
  def in_stock?
    stock > 0
  end
  
  def active?
    active
  end
  
  def inactive?
    !active
  end
  
  def validity_display
    return "Lifetime" if validity_type.blank? || validity_duration.blank?
    "#{validity_duration} #{validity_type.capitalize}"
  end
  
  def validity_price_display
    return price if validity_price.blank?
    validity_price
  end
  
  def has_validity_options?
    validity_type.present? && validity_duration.present?
  end
  

  
  def get_validity_options
    validity_options.active.sorted_by_duration
  end
  
  def default_validity_option
    validity_options.default.first || validity_options.sorted_by_duration.first
  end
  
  # Trial-related methods
  def has_trial_option?
    validity_options.exists?(duration_type: 'days', duration_value: 1)
  end
  
  def trial_option
    validity_options.find_by(duration_type: 'days', duration_value: 1)
  end
  
  def trial_price
    trial_option&.price || 0
  end
  
  def trial_usage_count
    trial_usages.count
  end
  
  def recent_trial_usages(limit = 10)
    trial_usages.recent.limit(limit)
  end
  
  def users_who_used_trial
    User.joins(:trial_usages).where(trial_usages: { product_id: id })
  end
  
  # Feature management methods
  def add_feature(feature)
    self.features ||= []
    feature = feature.to_s.strip
    self.features << feature unless feature.blank? || self.features.include?(feature)
  end
  
  def remove_feature(feature)
    self.features ||= []
    self.features.delete(feature.to_s)
  end
  
  def has_feature?(feature)
    return false if self.features.blank?
    self.features.include?(feature.to_s)
  end
  
  def features_list
    return [] if self.features.blank?
    self.features.is_a?(Array) ? self.features : []
  end
  
  private
  
  def ensure_features_array
    # Ensure features is always an array
    Rails.logger.debug "ensure_features_array called, current features: #{self.features.inspect} (class: #{self.features.class})"
    
    if self.features.nil?
      Rails.logger.debug "Features is nil, setting to empty array"
      self.features = []
    elsif !self.features.is_a?(Array)
      Rails.logger.debug "Features is not an array, converting to array"
      self.features = [self.features].compact
    else
      Rails.logger.debug "Features is already an array: #{self.features.inspect}"
    end
  end
  
  def ensure_default_validity_option
    # Ensure at least one validity option exists for this product
    # Skip if flag is set (e.g., during seeding)
    return if self.class.skip_default_validity_option_creation
    
    if validity_options.empty?
      Rails.logger.debug "No validity options found, creating default trial option"
      validity_options.create!(
        duration_type: 'days',
        duration_value: 1,
        price: 1,
        label: '1 Day Trial',
        is_default: true,
        sort_order: 0,
        active: true
      )
    end
  end
  
  def ensure_single_default_validity_option
    # Get all default validity options for this product
    default_options = validity_options.where(is_default: true)
    
    # If more than one default option exists, keep only the first one
    if default_options.count > 1
      first_default = default_options.first
      validity_options.where(is_default: true).where.not(id: first_default.id).update_all(is_default: false)
    end
  end
end
