class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.string :name, null: false
      t.string :phone, null: false
      t.string :email, null: false
      t.string :source
      t.string :role
      t.string :requirement
      t.text :message, null: false
      t.string :status, default: 'new'

      t.timestamps
    end
    
    add_index :contacts, :email
    add_index :contacts, :status
    add_index :contacts, :created_at
  end
end
