class CreateOffers < ActiveRecord::Migration
  def change
    create_table :offers do |t|
      t.string :uuid, index: true
      t.string :internal_name, index: true  # may be used to resolve reference as an alternative to uuid
      t.string :name
      t.text   :summary
      t.text   :details
      t.references :profile, index: true, foreign_key: true   # entity providing the offer. may differ from campaign owner for abuntoo use case
      t.references :campaign, index: true, foreign_key: true  # primary campaign assocaited with this offer, may have soft references
      t.string :kind
      t.string :status
      t.json   :data
      t.timestamps null: false

      t.decimal :financial_value
      t.integer :limit
      t.integer :allocated, null: false, default: 0
      t.date    :expiry_date
      t.integer :minimum_contribution, null: false, default: 0
      # for subscriptions
      t.integer :contribution_interval_count  # usually 1
      t.string  :contribution_interval_units  # month, year
    end

    add_reference :transactions, :offer, index: true, foreign_key: true

  end
end
