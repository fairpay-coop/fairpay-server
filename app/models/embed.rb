class Embed < ActiveRecord::Base
  include DataFieldable
  include UuidAssignable

  # create_table :embeds do |t|
  #   t.string :uuid, index: true
  #   t.references :profile, index: true, foreign_key: true
  #   t.string :kind
  #   t.json :data
  #   t.timestamps null: false
  # add_column :embeds, :name, :string
  # not sure yet if we need an internal name here
  # add_column :embeds, :internal_name, :string


  belongs_to :profile

  after_initialize :assign_uuid


  def display_name
    name || ("#{profile&.display_name} (#{uuid})")
  end

  # returns list of names of merchant config type to display for the embed
  # either honor a specific embed param, or default to all available merchant configs
  def payment_types
    get_data_field(:payment_types) || all_payment_configs.map(&:kind)
    # todo: add validation that merchant configs exist when specific list given
  end

  def all_merchant_configs
    profile.merchant_configs
  end

  def all_payment_configs
    # todo: add a category of configs to more cleanly support this filter
    merchant_configs.find_by(kind: ['authorizenet', 'braintree', 'dwolla', 'paypal'])
  end


  def payment_configs
    payment_types.map { |type| merchant_config_for_type(type) }
  end

  def merchant_configs
    payment_types.map { |type| merchant_config_for_type(type) }
  end


  def merchant_config_for_type(payment_type)
    result = all_merchant_configs.find_by(kind: payment_type)
    raise "merchant config now found for payment type: #{payment_type}"  unless result
    result
  end

  def payment_service_for_type(payment_type)
    merchant_config_for_type(payment_type).payment_service
  end

  #todo: still used?
  def card_merchant_config
    # todo: add a category of configs to more cleanly support this filter
    # all_merchant_configs.find_by(kind: ['authorizenet', 'braintree'])
    payment_configs.detect(&:card?)   # could be better optimized
  end

  def mailing_list_config
    mailing_list_type = get_data_field(:mailing_list)
    mailing_list_type = mailing_list_type['type']  if mailing_list_type.is_a?(Hash)
    if mailing_list_type
      all_merchant_configs.find_by(kind: mailing_list_type)
    else
      nil
    end
  end

  def mailing_list_service
    mailing_list_config&.service
  end

  def mailing_list_enabled
    mailing_list_config.present?
  end

  def recurrence_enabled
    get_data_field(:recurrence).present?
  end

  RECURRENCE_LABELS = {none: "One Time", month: "Monthly", year: "Yearly"}

  def recurrence_options
    [[:none, "One Time"], [:month, "Monthly"], [:year, "Yearly"]]
    values = get_data_field(:recurrence)
    values.map do |value|
      checked = (value.to_sym == :none)  #todo: make this configurable?
      { value: value, label: RECURRENCE_LABELS[value.to_sym], checked: checked }
    end
  end

  #todo: data driven recurrence choices

  #todo: data driven contribution amount choices

  # this can all be nicely refactored
  def card_payment_service
    card_merchant_config&.payment_service
  end

  # still used?
  def paypal_service
    merchant_config = all_merchant_configs.find_by(kind: 'paypal')
    merchant_config&.payment_service
  end

  def dwolla_service
    DwollaService.instance
  end

  def step1(params)
    email = params[:email]
    name = params[:name]
    amount = params[:amount]
    recurrence = params[:recurrence]
    recurrence = nil  if recurrence == 'none'
    mailing_list = params[:mailing_list]

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
        recurrence: recurrence,
        mailing_list: mailing_list
    )
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
