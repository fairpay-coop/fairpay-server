class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :uuid, index: true
      t.string :kind
      t.string :status
      t.references :payor, index: true
      t.references :payee, index: true
      t.references :embed, foreign_key: true
      t.references :payment_source, foreign_key: true
      t.references :merchant_config, foreign_key: true
      t.references :parent, index: true
      t.decimal :base_amount
      t.decimal :estimated_fee
      t.decimal :surcharged_fee
      t.decimal :platform_fee
      t.decimal :paid_amount
      t.string :description
      t.json :data
      t.string :recurrence
      t.timestamps null: false
    end

    add_foreign_key :transactions, :profiles, column: :payor_id
    add_foreign_key :transactions, :profiles, column: :payee_id
    add_foreign_key :transactions, :transactions, column: :parent_id

  end
end
