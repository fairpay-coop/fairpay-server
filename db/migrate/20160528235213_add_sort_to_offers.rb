class AddSortToOffers < ActiveRecord::Migration
  def change
    add_column :offers, :sort, :string, index: true
  end
end
