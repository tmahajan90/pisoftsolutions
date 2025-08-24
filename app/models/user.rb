require 'bcrypt'

class User < ApplicationRecord
  has_secure_password
  
  has_many :orders, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_one :cart, -> { order(created_at: :desc) }
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :phone, presence: true, length: { minimum: 10, maximum: 20 }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
  
  before_validation :normalize_email
  
  def self.find_or_create_by_email(email, attributes = {})
    user = find_by(email: email.downcase.strip)
    if user
      user.update(attributes) if attributes.any?
      user
    else
      create(attributes.merge(email: email.downcase.strip))
    end
  end
  
  def full_name
    name.present? ? name : email.split('@').first
  end
  
  private
  
  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
