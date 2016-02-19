class Transaction < ActiveRecord::Base

  # create_table :transactions do |t|
  #   t.string :uuid, index: true
  #   t.string :kind
  #   t.references :payor, index: true
  #   t.references :payee, index: true
  #   t.references :embed, foreign_key: true
  #   t.references :payment_source, foreign_key: true
  #   t.references :merchant_config, foreign_key: true
  #   t.references :parent, index: true, foreign_key: true  - used to relate a recurrent payment or refund to original transaction
  #   t.decimal :amount
  #   t.string :description
  #   t.json :data
  #   t.string :recurrence
  #   t.timestamps null: false


  belongs_to :payor, class_name: 'Profile'
  belongs_to :payee, class_name: 'Profile'
  belongs_to :embed
  belongs_to :payment_source
  belongs_to :merchant_config
  belongs_to :parent, class_name: 'Transaction'


  # todo: factor to ActiveRecord::Base

  after_initialize :assign_uuid

  def assign_uuid
    self.uuid ||= SecureRandom.urlsafe_base64(8)
  end

  def self.by_uuid(uuid)
    self.find_by(uuid: uuid)
  end


  #todo: think more about best encapsulation layering - for now lives in Embed
  # def pay_via_dwolla
  #   payor.dwolla_token.make_payment(payee.dwolla_token, base_amount)
  #   transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)
  #
  # end

end
