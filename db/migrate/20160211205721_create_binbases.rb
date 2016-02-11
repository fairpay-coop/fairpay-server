class CreateBinbases < ActiveRecord::Migration
  def change
    create_table :binbases do |t|
      t.string :bin, index: true
      t.string :card_brand
      t.string :card_type
      t.string :card_category
      t.string :country_iso
      t.string :org_website
      t.string :org_phone
      t.references :binbase_org
      t.timestamps null: false
    end
  end
end
