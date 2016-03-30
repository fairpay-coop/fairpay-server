class Embed < ActiveRecord::Base
  include DataFieldable
  include UuidAssignable

  # create_table :embeds do |t|
  #   t.string :uuid, index: true
  #   t.references :profile, index: true, foreign_key: true
  #   t.string :kind
  #   t.json :data
  #   t.timestamps null: false
  #   t.string :name
  #   t.string :internal_namae
  # add_column :embeds, :disabled, :boolean, default: false, null: false  #todo: replace this with a 'status'?

  belongs_to :profile
  belongs_to :campaign

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
    #todo: memoize this
    payment_types.map { |identifier| merchant_config_for_identifier(identifier) }
  end

  def payment_config_for_type(payment_type)
    payment_configs.find{ |mc| mc.kind == payment_type.to_s }
  end

  def payment_service_for_type(payment_type)
    payment_config_for_type(payment_type).payment_service
  end



  # def merchant_configs
  #   payment_types.map { |type| merchant_config_for_type(type) }
  # end


  # def merchant_config_for_type(payment_type)
  #   # result = MerchantConfig.find_by(internal_name: payment_type)
  #   # # todo: security checks that this profile has access to named merchant config
  #   # result = all_merchant_configs.find_by(kind: payment_type)  unless result
  #
  #   result = merchant_configs.find{ |mc| mc.kind == payment_type.to_s || mc.internal_name == payment_type.to_s }
  #
  #
  #   raise "merchant config now found for payment type: #{payment_type}"  unless result
  #   result
  # end

  # identifier is either the 'internal_name' or 'kind'
  def merchant_config_for_identifier(identifier)
    result = MerchantConfig.find_by(internal_name: identifier)
    # todo: security checks that this profile has access to named merchant config
    result = all_merchant_configs.find_by(kind: identifier)  unless result
    raise "merchant config not found for identifier: #{identifier}"  unless result
    result
  end


  def card_merchant_config
    # todo: add a category of configs to more cleanly support this filter
    # all_merchant_configs.find_by(kind: ['authorizenet', 'braintree'])
    payment_configs.detect(&:card?)   # could be better optimized
  end


  def dwolla_service
    payment_service_for_type(:dwolla)
  end


  # this can all be nicely refactored
  def card_payment_service
    card_merchant_config&.payment_service
  end

  # still used?
  def paypal_service
    # merchant_config = all_merchant_configs.find_by(kind: 'paypal')
    # merchant_config&.payment_service
    payment_service_for_type(:paypal)
  end




  def mailing_list_config
    # mailing_list_type = get_data_field(:mailing_list)
    # mailing_list_type = mailing_list_type['type']  if mailing_list_type.is_a?(Hash)
    # if mailing_list_type
    #   all_merchant_configs.find_by(kind: mailing_list_type)
    # else
    #   nil
    # end

    mailing_list_data = get_data_field(:mailing_list)
    if mailing_list_data.is_a?(Hash)
      identifier = mailing_list_data['type']
    else
      identifier = mailing_list_data  #todo: confirm is a string
    end
    if identifier
      merchant_config_for_identifier(identifier)
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
    #todo: rename this field to 'recurrences' since it's a list?
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

  def suggested_amounts
    get_data_field(:suggested_amounts)
  end

  def currency_format
    '${0}'
  end

  FEE_ALLOCATION_VALUES = [:payee, :split, :payor]

  def fee_allocations
    result = get_data_field(:fee_allocations)
    result = [:payee]  unless result.present?
    result
  end

  def fee_allocation_options(transaction = nil)
    values = fee_allocations
    selected = transaction ? transaction.fee_allocation : values.first
    values.map do |value|
      checked = (value == selected)
      { value: value, label: fee_allocation_label(value, transaction), checked: checked }
    end
  end

  def fee_allocation_label(value, transaction = nil)
    case value.to_sym
      when :payee
        transaction&.payee&.name || 'Payee'
      when :split
        'Split 50/50'
      when :payor
        'Myself'
      else
        raise "unexpected fee allocation label: #{value}"
    end
  end

  def fee_allocation_label_merchant(value, transaction = nil)
    case value.to_sym
      when :payee  #todo: use 'mode' config flag for better labels
        'Payee'
      when :split
        'Split 50/50'
      when :payor
        'Payor'
      else
        raise "unexpected fee allocation label: #{value}"
    end
  end

  def self.allocation_ratio(value)
    case value.to_sym
      when :payee
        0.0
      when :split
        0.5
      when :payor
        1.0
      else
        raise "unexpected fee allocation label: #{value}"
    end
  end

  def capture_memo
    get_data_field(:capture_memo)  #todo better handling of json attrs
  end

  #todo: data driven recurrence choices

  #todo: data driven contribution amount choices



  def step1(params)
    puts "embed - step1 - params: #{params}"
    email = params[:email]&.downcase  #todo: confirm if devise is already also doing this
    name = params[:name]
    amount = params[:amount]
    recurrence = params[:recurrence]
    recurrence = nil  if recurrence == 'none'
    mailing_list = params[:mailing_list]
    description = params[:description]
    memo = params[:memo]
    offer_uuid = params[:offer_uuid]
    return_url = params[:return_url]
    correlation_id = params[:correlation_id]

    raise "email required" unless email.present?
    payor = Profile.find_by(email: email)
    unless payor
      name = email  unless name.present?  # don't require 'name' as the api level, default to email
      payor = Profile.create!(email: email, name: name)
    end
    fee_allocation = fee_allocations.first

    offer = Offer.resolve(offer_uuid, required:false)

    transaction = Transaction.create!(
        embed: self,
        payee: self.profile,
        payor: payor,
        base_amount: amount,
        status: :provisional,
        fee_allocation: fee_allocation,
        recurrence: recurrence,
        mailing_list: mailing_list,
        description: description,
        offer: offer
    )
    transaction.update_data_field(:memo, memo)  #todo, clean up handling of json attrs
    transaction.update_data_field(:offer_uuid, offer_uuid)  if offer_uuid # save raw uuid just in case relation lookup failed
    transaction.update_data_field(:return_url, return_url)  if return_url # where to return to at end of payment flow
    transaction.update_data_field(:correlation_id, correlation_id)  if correlation_id # where to return to at end of payment flow
    transaction
  end

  # expected params: :transaction_uuid, :fee_allocation
  def update_fee_allocation(params)
    transaction_uuid = params[:transaction_uuid]
    transaction = Transaction.by_uuid(transaction_uuid)

    allocation = params[:fee_allocation]
    #todo: validation
    transaction.update!(fee_allocation: allocation)
    transaction.fee_allocation
  end


  #todo: rename this to 'submit_payment'
  def step2(params)
    transaction_uuid = params[:transaction_uuid]
    transaction = Transaction.by_uuid(transaction_uuid)

    transaction.perform_payment(params)

    transaction
  end


  def send_dwolla_info(params)
    tran_uuid = params[:transaction_uuid]
    transaction = Transaction.by_uuid(tran_uuid)
    puts "send dwolla info - tran id: #{tran_uuid}"
    PaymentNotifier.dwolla_info(transaction).deliver_now
    {status: :success}
  end

  # fetches instance by either uuid or internal name
  # def self.resolve(identifier, required:true)
  #   result = by_uuid(identifier) || Embed.find_by_internal_name(identifier)
  #   raise "Embed not found for identifier: #{identifier}"  if required && !result
  #   result
  # end

  def present_offers
    campaign&.offers.present?
  end

  def offers
    campaign&.available_offers
  end


  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :name, :financial_total, :supporter_total, :financial_goal, :financial_pcnt
    expose :offers, using: Offer::Entity
  end


end
