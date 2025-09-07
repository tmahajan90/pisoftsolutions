class AddPaymentGatewayToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :payment_gateway, :string, default: 'razorpay'
    add_column :orders, :payment_gateway_order_id, :string
    add_column :orders, :payment_gateway_payment_id, :string
    add_column :orders, :payment_gateway_signature, :text
    
    add_index :orders, :payment_gateway
    add_index :orders, :payment_gateway_order_id
    add_index :orders, :payment_gateway_payment_id
  end
end
