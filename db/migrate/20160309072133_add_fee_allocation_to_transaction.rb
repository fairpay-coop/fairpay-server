class AddFeeAllocationToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :fee_allocation, :string
    rename_column :transactions, :surcharged_fee, :allocated_fee
  end
end
