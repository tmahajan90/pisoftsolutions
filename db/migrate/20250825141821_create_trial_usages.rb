class CreateTrialUsages < ActiveRecord::Migration[7.1]
  def change
    create_table :trial_usages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.datetime :used_at

      t.timestamps
    end
    
    add_index :trial_usages, [:user_id, :product_id], unique: true
  end
end
