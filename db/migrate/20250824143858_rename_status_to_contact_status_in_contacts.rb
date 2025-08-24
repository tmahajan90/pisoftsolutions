class RenameStatusToContactStatusInContacts < ActiveRecord::Migration[7.1]
  def change
    rename_column :contacts, :status, :contact_status
  end
end
