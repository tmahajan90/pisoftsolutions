class Contact < ApplicationRecord
  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :phone, presence: true, length: { minimum: 10, maximum: 20 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true, length: { minimum: 10, maximum: 2000 }
  
  # Enums for contact_status
  enum contact_status: {
    new: 'new',
    in_progress: 'in_progress',
    responded: 'responded',
    closed: 'closed'
  }
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(contact_status: 'new') }
  scope :pending, -> { where(contact_status: ['new', 'in_progress']) }
  
  # Callbacks
  before_create :set_default_status
  
  # Instance methods
  def full_details
    "#{name} (#{email}) - #{requirement || 'General Inquiry'}"
  end
  
  def mark_as_responded!
    update(contact_status: 'responded')
  end
  
  def mark_as_closed!
    update(contact_status: 'closed')
  end
  
  def mark_as_in_progress!
    update(contact_status: 'in_progress')
  end
  
  private
  
  def set_default_status
    self.contact_status ||= 'new'
  end
end
