class AddMissingDeviseFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    
    # Add index for reset_password_token
    add_index :users, :reset_password_token, unique: true
  end
end
