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
  end


end
