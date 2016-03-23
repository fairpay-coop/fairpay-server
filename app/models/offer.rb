class Offer < ActiveRecord::Base
  include DataFieldable
  include UuidAssignable

  # create_table :offers do |t|
  #   t.string :uuid, index: true
  #   t.string :internal_name, index: true  # may be used to resolve reference as an alternative to uuid
  #   t.string :name
  #   t.text   :summary
  #   t.text   :details
  #   t.references :profile, index: true, foreign_key: true   # entity providing the offer. may differ from campaign owner for abuntoo use case
  #   t.references :campaign, index: true, foreign_key: true  # primary campaign assocaited with this offer, may have soft references
  #   t.string :kind
  #   t.string :status
  #   t.json   :data
  #   t.timestamps null: false
  #   t.decimal :financial_value
  #   t.integer :limit
  #   t.integer :allocated
  #   t.date    :expiry_date
  #   t.integer :minimum_payment
  #   # for subscriptions
  #   t.integer :payment_interval_count  # usually 1
  #   t.string  :payment_interval_units  # month, year


  belongs_to :profile
  belongs_to :campaign

  after_initialize :assign_uuid


  def display_name
    name
  end



end
