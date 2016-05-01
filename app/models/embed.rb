class Embed < ActiveRecord::Base
  include DataFieldable
  include UuidAssignable
  include ApplicationHelper

  # create_table :embeds do |t|
  #   t.string :uuid, index: true
  #   t.references :profile, index: true, foreign_key: true
  #   t.string :kind
  #   t.json :data
  #   t.timestamps null: false
  #   t.string :name
  #   t.string :internal_namae
  # add_column :embeds, :disabled, :boolean, default: false, null: false  #todo: replace this with a 'status'?

  belongs_to :profile   # perhaps rename this to payee
  belongs_to :campaign

  attr_data_field :payment_types
  attr_data_field :mailing_list
  attr_data_field :recurrence #todo: rename to recurrences
  attr_data_field :suggested_amounts
  attr_data_field :fee_allocations
  attr_data_field :capture_memo
  attr_data_field :consider_this
  attr_data_field :amount
  attr_data_field :description
  attr_data_field :return_url
  attr_data_field :capture_address   # list of address type: mailing, billing, shipping.  if present, then capture specified full addresses for payor
  attr_data_field :theme
  attr_data_field :headline
  attr_data_field :subheadline
  attr_data_field :page_title   # html head title tag

  # if assigned present option on 'finished' view to provide preauthorization to automatically charge saved payment information once per specified interval.
  # subfields: interval_count, interval_units, interval_description
  attr_data_field :request_preauthorization


  after_initialize :assign_uuid


  def display_name
    name || ("#{profile&.display_name} (#{uuid})")
  end

  # note, removing the default to all available merchant types. want to force that to be explicit
  # returns list of names of merchant config type to display for the embed
  # either honor a specific embed param, or default to all available merchant configs
  # def payment_types
  #   get_data_field(:payment_types) || all_payment_configs.map(&:kind)
  #   # todo: add validation that merchant configs exist when specific list given
  # end

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

    mailing_list_data = mailing_list
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
    recurrence.present?
  end

  RECURRENCE_LABELS = {none: "One Time", month: "Monthly", year: "Yearly"}

  def recurrence_options
    [[:none, "One Time"], [:month, "Monthly"], [:year, "Yearly"]]
    values = recurrence
    values&.map do |value|
      checked = (value.to_sym == :none)  #todo: make this configurable?
      { value: value, label: RECURRENCE_LABELS[value.to_sym], checked: checked }
    end
  end

  #todo: automatically expose attributes via concern

  # def suggested_amounts
  #   get_data_field(:suggested_amounts)
  # end
  #
  # def consider_this
  #   get_data_field(:consider_this)
  # end

  def payee
    profile
  end

  def currency_format
    '${0}'
  end

  FEE_ALLOCATION_VALUES = [:payee, :split, :payor]

  def resolve_fee_allocations
    result = fee_allocations
    result = [:payee]  unless result.present?
    result
  end

  def fee_allocation_options(transaction = nil)
    values = resolve_fee_allocations
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

  # def capture_memo
  #   get_data_field(:capture_memo)  #todo better handling of json attrs
  # end

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
    offer_uuid = params[:offer_uuid]  # note, may be a comma separated list
    return_url = params[:return_url]
    correlation_id = params[:correlation_id]
    auth_token = params[:auth_token]
    authenticated_email = params[:authenticated_email]

    authenticated_profile = resolve_authenticated_profile(params)

    if email.blank? && authenticated_profile.present?
      puts "using auth0 authenticted email"
      email = authenticated_profile.email
    end

    if email.present?
      if email != '_deferred_'
        payor = Profile.find_or_create(email: email, name: name)
      else
        puts "email capture deferred"
      end
    else
      raise "email required"  unless step1_email_optional
    end

    if authenticated_profile
      profile_authenticated = authenticated_profile.email == email
    else
      profile_authenticated = false
    end
    puts "auth token: #{auth_token}, profile_authenticated: #{profile_authenticated}"

    fee_allocation = resolve_fee_allocations.first

    offer = Offer.resolve(offer_uuid, required:false)  # note, will parse out first value if a list

    transaction = Transaction.create!(
        embed: self,
        payee: self.profile,
        payor: payor,
        profile_authenticated: profile_authenticated,
        base_amount: amount,
        status: :provisional,
        fee_allocation: fee_allocation,
        recurrence: recurrence,
        mailing_list: mailing_list,
        description: description,
        offer: offer,
        offer_uuid: offer_uuid
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

  def update_auth_token(params)
    transaction_uuid = params[:transaction_uuid]
    transaction = Transaction.by_uuid(transaction_uuid)

    auth_token = params[:auth_token]

    payor = resolve_profile_from_token(auth_token)
    if payee
      transaction.update!(payor_id: payor.id, profile_authenticated: true)
      transaction
    else
      raise "unable to resolve profile from token: #{auth_token}"
    end
  end


  def submit_address(transaction_uuid, address_data)
    puts "transaction uuid: #{transaction_uuid}"
    transaction = Transaction.by_uuid(transaction_uuid)
    puts "fetched tran: #{transaction}"
    transaction.submit_address(address_data)
    transaction
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

  # base path to use for layout and rendered views
  def resolve_theme
    theme || 'default'
  end

  def resolve_headline
    headline || name
  end

  def entity
    Entity.new(self)
  end

  #todo: refactor most of the embed data into the entity mapping and nest an 'embed' instance into the embed_data api result
  class Entity < Grape::Entity
    expose :uuid, :name, :suggested_amounts, :currency_format, :mailing_list_enabled, :capture_memo, :consider_this, :recurrence_options,
           :fee_allocation_options, :capture_address
    # expose :payment_configs_data, as: :payment_configs
    expose :campaign, using: Campaign::Entity
    expose :payee, using: Profile::Entity
    expose :resolve_theme, as: :theme
    expose :resolve_headline, as: :headline
    expose :subheadline, :page_title

    # expose :offers, using: Offer::Entity
  end

  def payment_configs_data(transaction = nil)
    payment_configs.map do |merchant_config|
      merchant_config.widget_data(transaction)
    end
  end

  def embed_data(params = {})
    # payment_datas = payment_configs.map do |merchant_config|
    #   merchant_config.widget_data(nil, nil)
    # end
    session_data = params[:session_data]
    authenticated_profile = resolve_authenticated_profile(session_data)

    amount = amount_param(params, :amount) || get_data_field(:amount)
    description = params[:description] || get_data_field(:description)
    return_url = params[:return_url] || get_data_field(:return_url)
    correlation_id = params[:correlation_id]

    offer_uuid = params[:offer]
    puts "offer_uuid: #{offer_uuid}"
    if offer_uuid
      puts "passed in offer uuid: #{offer_uuid}"
      assigned_offer = Offer.resolve(offer_uuid, required:false)
    else
      assigned_offer = nil
    end

    email = params[:email]

    result = {
        embed: Embed::Entity.represent(self),
        authenticated_profile: Profile::Entity.represent(authenticated_profile),
        payment_configs: payment_configs_data(nil),
        amount: amount,
        description: description,
        return_url: return_url,
        correlation_id: correlation_id,
        assigned_offer: Offer::Entity.represent(assigned_offer),
        session_data: session_data,

        #todo: remove duplicate embed fields below once widget usage migrated
        # session_email: session_email,
        campaign: Campaign::Entity.represent(campaign),
        uuid: uuid,
        name: name,
        suggested_amounts: suggested_amounts,
        currency_format: currency_format,
        mailing_list_enabled: mailing_list_enabled,
        capture_memo: capture_memo,
        consider_this: consider_this,
        allocation_options: fee_allocation_options(nil),
        recurrence_options: recurrence_options
    }
    result
  end

  # if session_data && session_data[:auth_token].present?
  #   user = User.find_by(auth_token: session_data[:auth_token])
  #   puts "auth token user: #{user}"
  #   user.profile
  # else
  #   nil
  # end


  def self.resolve_from_host(host)
    puts "resolve from host: #{host}"
    head = host.split('.').first
    resolve(head, required: false)
  end

end
