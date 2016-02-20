class Embed < ActiveRecord::Base

  # create_table :embeds do |t|
  #   t.string :uuid, index: true
  #   t.references :profile, index: true, foreign_key: true
  #   t.string :kind
  #   t.json :data
  #   t.timestamps null: false


  belongs_to :profile

  after_initialize :assign_uuid

  # todo: factor to ActiveRecord::Base
  def assign_uuid
    self.uuid ||= SecureRandom.urlsafe_base64(8)
  end

  def self.by_uuid(uuid)
    self.find_by(uuid: uuid)
  end

  # is there a clever active record declaration for this?
  def merchant_configs
    profile.merchant_configs
  end


  def card_payment_service
    merchant_config = merchant_configs.find_by(kind: 'authorizenet')
    payment_service = merchant_config.payment_service
  end

  def step1(email, name, amount)
    payor = Profile.find_by(email: email)
    unless payor
      payor = Profile.create!(email: email, name: name)
    end

    transaction = Transaction.create!(embed: self, payee: self.profile, payor: payor, base_amount: amount, status: :provisional)
  end


  def step2(params)
    transaction_uuid = params[:transaction_uuid]
    merchant_config_id = params[:merchant_config_id]
    payment_type = params[:payment_type]



    case payment_type
      when 'dwolla'
        pay_via_dwolla(params)

      when 'card'
        transaction = Transaction.by_uuid(transaction_uuid)
        # merchant_config = MerchantConfig.find(merchant_config_id)
        #todo: resolve based on 'payment_type' param
        merchant_config = transaction.embed.merchant_configs.first

        estimated_fee = transaction.base_amount * 0.03 + 0.30
        paid_amount = transaction.base_amount

        data = params.slice(:card_number, :card_mmyy, :card_cvv)
        data[:amount] = paid_amount
        puts "data: #{data}"

        payment_service = merchant_config.payment_service
        payment_service.charge(data)
        transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)
        transaction

      else
        raise "unexpected payment type: #{payment_type}"
    end

  end

  def pay_via_dwolla(params)
    transaction_uuid = params[:transaction_uuid]
    # merchant_config_id = params[:merchant_config_id]
    funding_source_id = params[:funding_source_id]

    transaction = Transaction.by_uuid(transaction_uuid)
    estimated_fee = 0.00
    paid_amount = transaction.base_amount + estimated_fee

    dwolla_service = DwollaService.instance
    # transaction.payor.dwolla_token.refresh
    # transaction.payee.dwolla_token.refresh
    dwolla_service.make_payment(transaction.payor.dwolla_token, transaction.payee.dwolla_token, funding_source_id, paid_amount)

    # transaction.payor.dwolla_token.make_payment(transaction.payee.dwolla_token, transaction.base_amount)
    transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)
    transaction
  end

end
