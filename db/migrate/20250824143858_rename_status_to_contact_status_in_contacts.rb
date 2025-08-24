class RenameStatusToContactStatusInContacts < ActiveRecord::Migration[7.1]
  def change
    rename_column :contacts, :status, :contact_status
    
    # Update existing data to use 'unread' instead of 'new'
    execute "UPDATE contacts SET contact_status = 'unread' WHERE contact_status = 'new'"
  end
end
