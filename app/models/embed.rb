class Embed < ActiveRecord::Base
  include DataFieldable
  include UuidAssignable

  # create_table :embeds do |t|
  #   t.string :uuid, index: true
  #   t.references :profile, index: true, foreign_key: true
  #   t.string :kind
  #   t.json :data
  #   t.timestamps null: false


  belongs_to :profile

  after_initialize :assign_uuid


  # returns list of names of merchant config type to display for the embed
  # either honor a specific embed param, or default to all available merchant configs
  def payment_types
    get_data_field(:payment_types) || profile.merchant_configs.map(&:kind)
    # todo: add validation that merchant configs exist when specific list given
  end

  def merchant_configs
    payment_types.map { |type| merchant_config_for_type(type) }
  end


  def merchant_config_for_type(payment_type)
    result = profile.merchant_configs.find_by(kind: payment_type)
    raise "merchant config now found for payment type: #{payment_type}"  unless result
    result
  end

  def payment_service_for_type(payment_type)
    merchant_config_for_type(payment_type).payment_service
  end


  def card_merchant_config
    # todo: add a category of configs to more cleanly support this filter
    merchant_config = merchant_configs.find_by(kind: ['authorizenet', 'braintree'])
  end

  # this can all be nicely refactored
  def card_payment_service
    card_merchant_config&.payment_service
  end

  def paypal_service
    merchant_config = merchant_configs.find_by(kind: 'paypal')
    payment_service = merchant_config.payment_service
  end

  def dwolla_service
    DwollaService.instance
  end

  def step1(params) #email, name, amount)
    email = params[:email]
    name = params[:name]
    amount = params[:amount]
    recurrence = params[:recurrence]
    recurrence = nil  if recurrence == 'none'
    raise "email required" unless email.present?
    payor = Profile.find_by(email: email)
    unless payor
      name = email  unless name.present?  # don't require 'name' as the api level, default to email
      payor = Profile.create!(email: email, name: name)
    end
    transaction = Transaction.create!(
        embed: self,
        payee: self.profile,
        payor: payor,
        base_amount: amount,
        status: :provisional,
        recurrence: recurrence)
  end


  def step2(params)
    # merchant_config_id = params[:merchant_config_id]
    # payment_type = params[:payment_type]&.to_sym

    transaction_uuid = params[:transaction_uuid]
    transaction = Transaction.by_uuid(transaction_uuid)

    transaction.perform_payment(params)

    # payment_service = payment_service_for_type(payment_type)
    # paid_amount,fee = payment_service.handle_payment(transaction, params)
    #
    # transaction.update!(
    #     status: 'completed',
    #     payment_type: payment_type,
    #     paid_amount: paid_amount,
    #     estimated_fee: fee
    # )
    #
    # if transaction.recurrence
    #   recurring = RecurringPayment.create!(
    #       master_transaction: transaction,
    #       interval_units: transaction.recurrence,
    #       interval_count: 1,
    #       expires_date: nil,
    #       status: :active
    #   )
    #
    #   transaction.update!(recurring_payment: recurring)
    #
    #   recurring.increment_next_date
    #
    # end

    transaction
  end

  # def pay_via_card(params)
  #   transaction_uuid = params[:transaction_uuid]
  #   transaction = Transaction.by_uuid(transaction_uuid)
  #   # merchant_config = MerchantConfig.find(merchant_config_id)
  #
  #   # payment_service = merchant_config.payment_service
  #   payment_service = card_payment_service
  #
  #   estimated_fee = payment_service.calculate_fee(transaction.base_amount, params)
  #   paid_amount = transaction.base_amount
  #
  #   data = params.slice(:card_number, :card_mmyy, :card_cvv)
  #   data[:amount] = paid_amount
  #   puts "data: #{data}"
  #
  #   payment_service.charge(data)
  #
  #   # #todo: factor out the transaction update
  #   # transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)
  #   # transaction
  #   [paid_amount, estimated_fee]
  # end

  # def pay_via_dwolla(params)
  #   transaction_uuid = params[:transaction_uuid]
  #   # merchant_config_id = params[:merchant_config_id]
  #   funding_source_id = params[:funding_source_id]
  #
  #   transaction = Transaction.by_uuid(transaction_uuid)
  #   estimated_fee = 0.00
  #   paid_amount = transaction.base_amount + estimated_fee
  #
  #   dwolla_service = DwollaService.instance
  #   # transaction.payor.dwolla_token.refresh
  #   # transaction.payee.dwolla_token.refresh
  #   dwolla_service.make_payment(transaction.payor.dwolla_token, transaction.payee.dwolla_token, funding_source_id, paid_amount)
  #
  #   # # transaction.payor.dwolla_token.make_payment(transaction.payee.dwolla_token, transaction.base_amount)
  #   # transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)
  #   # transaction
  #   [paid_amount, estimated_fee]
  #
  # end

  # def pay_via_paypal(params)
  #   transaction_uuid = params[:transaction_uuid]
  #   transaction = Transaction.by_uuid(transaction_uuid)
  #
  #   payment_service = paypal_service()
  #
  #   estimated_fee = payment_service.calculate_fee(transaction.base_amount, params)
  #   paid_amount = transaction.base_amount  #todo fee allocation based on merchant config
  #
  #   paypal_service.complete_payment(params[:token], params[:payor_id], paid_amount)
  #
  #   # transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)
  #   # transaction
  #
  #   [paid_amount, estimated_fee]
  #
  # end
  #
end
