class CreateBinbaseOrgs < ActiveRecord::Migration
  def change
    create_table :binbase_orgs do |t|
      t.string :name
      t.string :country_iso
      t.string :website
      t.string :phone
      t.boolean :is_regulated
      t.timestamps null: false
    end
  end
end
