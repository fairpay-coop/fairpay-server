class Transaction < ActiveRecord::Base

  # create_table :transactions do |t|
  #   t.string :uuid, index: true
  #   t.string :kind
  #   t.string :status
  #   t.references :payor, index: true
  #   t.references :payee, index: true
  #   t.references :embed, foreign_key: true
  #   t.references :payment_source, foreign_key: true
  #   t.references :merchant_config, foreign_key: true
  #   t.references :parent, index: true
  #   t.decimal :base_amount
  #   t.decimal :estimated_fee
  #   t.decimal :surcharged_fee
  #   t.decimal :platform_fee
  #   t.decimal :paid_amount
  #   t.string :description
  #   t.json :data
  #   t.string :recurrence
  #   t.timestamps null: false
  #   t.strting :payment_type


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


  def card_fee_range
    embed.card_payment_service.calculate_fee(base_amount)
  end

  def card_fee_str
    low,high = card_fee_range
    "#{format_amount(low)}-#{format_amount(high)}"
  end

  def format_amount(amount)
    '%.2f' % amount
  end

  def paypal_fee
    embed.paypal_service.calculate_fee(base_amount)
  end

  def paypal_fee_str
    format_amount(embed.paypal_service.calculate_fee(base_amount))
  end

  #todo: think more about best encapsulation layering - for now lives in Embed
  # def pay_via_dwolla
  #   payor.dwolla_token.make_payment(payee.dwolla_token, base_amount)
  #   transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)
  #
  # end

end
