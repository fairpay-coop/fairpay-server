class CreateMerchantConfigs < ActiveRecord::Migration
  def change
    create_table :merchant_configs do |t|
      t.references :profile, index: true, foreign_key: true
      t.string :kind
      t.json :data

      t.timestamps null: false
    end
  end
end
