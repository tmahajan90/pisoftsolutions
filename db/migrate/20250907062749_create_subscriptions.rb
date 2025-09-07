class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :feature, null: false, foreign_key: true
      t.string :plan_name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :billing_cycle, null: false, default: 2
      t.integer :status, null: false, default: 0
      t.boolean :auto_renew, default: true
      t.integer :usage_limit
      t.text :features
      t.datetime :started_at
      t.datetime :last_billing_date
      t.datetime :next_billing_date
      t.integer :billing_count, default: 0
      t.datetime :cancelled_at
      t.text :cancellation_reason
      t.datetime :suspended_at
      t.text :suspension_reason
      t.datetime :effective_date

      t.timestamps
    end
    
    add_index :subscriptions, [:user_id, :feature_id]
    add_index :subscriptions, :status
    add_index :subscriptions, :next_billing_date
    add_index :subscriptions, :auto_renew
  end
end
