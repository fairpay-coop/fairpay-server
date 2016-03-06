class PaymentSource < ActiveRecord::Base
  include DataFieldable

  # create_table :payment_sources do |t|
  #   t.references :profile, index: true, foreign_key: true
  #   t.string :kind
  #   t.json :data
  #   t.timestamps null: false


  belongs_to :profile


end
