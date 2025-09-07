class CreateUserFeatures < ActiveRecord::Migration[7.1]
  def change
    create_table :user_features do |t|
      t.references :user, null: false, foreign_key: true
      t.references :feature, null: false, foreign_key: true
      t.references :subscription, null: true, foreign_key: true
      t.integer :status, null: false, default: 0
      t.boolean :trial_used, default: false
      t.datetime :trial_started_at
      t.datetime :trial_ends_at
      t.datetime :expires_at
      t.datetime :suspended_at
      t.text :suspension_reason

      t.timestamps
    end
    
    add_index :user_features, [:user_id, :feature_id], unique: true
    add_index :user_features, :status
    add_index :user_features, :expires_at
    add_index :user_features, :trial_ends_at
  end
end
