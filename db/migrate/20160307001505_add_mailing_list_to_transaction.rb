class AddMailingListToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :mailing_list, :string
  end
end
