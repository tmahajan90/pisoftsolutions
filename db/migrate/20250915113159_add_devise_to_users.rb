class AddDeviseToUsers < ActiveRecord::Migration[7.1]
  def change
    # Email field already exists, so we don't add it again
    add_column :users, :encrypted_password, :string
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    
    # Add indexes for Devise (email index already exists)
    add_index :users, :confirmation_token, unique: true
  end
end
