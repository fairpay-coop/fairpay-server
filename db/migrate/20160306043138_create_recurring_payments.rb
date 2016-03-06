class CreateRecurringPayments < ActiveRecord::Migration
  def change
    create_table :recurring_payments do |t|
      t.string :uuid, index: true
      t.string :status
      t.references :master_transaction
      t.integer :interval_count
      t.string :interval_units
      t.date :expires_date
      t.date :next_date
      t.json :data
      t.timestamps null: false

    end

    add_foreign_key :recurring_payments, :transactions, column: :master_transaction_id

    add_reference :transactions, :recurring_payment, index: true, foreign_key: true

  end
end
