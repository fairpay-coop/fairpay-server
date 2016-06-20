class AddReferenceNumberToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :reference_number, :string
  end
end
