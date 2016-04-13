class Transaction < ActiveRecord::Base
  include UuidAssignable
  include DataFieldable
  include ApplicationHelper

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
  #   t.decimal :allocated_fee   # customer paid fee surcharge - todo: rename this
  #   t.decimal :platform_fee
  #   t.decimal :paid_amount
  #   t.string :description
  #   t.json :data
  #   t.string :fee_allocation  : payee, split, payor
  #   t.string :recurrence
  #   t.reference :recurring_payment, index: true, foreign_key: true
  #   t.timestamps null: false
  #   t.string :payment_type
  #   t.string :mailing_list
  #  add_reference :transactions, :offer, index: true, foreign_key: true

  # data attributes:
  #   correlation_id - passed in and returned with confirmation redirect and/or callback
  #   return_url - where to redirect browser upon completion of playment flow (need both success & failure urls?)
  #   callback_url - where to post payment status to upon completion
  #   description - should this be here instead of a dedicated field?


  belongs_to :payor, class_name: 'Profile'
  belongs_to :payee, class_name: 'Profile'
  belongs_to :embed
  belongs_to :payment_source
  belongs_to :merchant_config
  belongs_to :recurring_payment
  belongs_to :offer

  # not yet used - but likely to be useful for cases like a refund
  belongs_to :parent, class_name: 'Transaction'


  attr_data_field :memo
  attr_data_field :offer_uuid
  attr_data_field :return_url
  attr_data_field :correlation_id
  attr_data_field :address_captured  # boolean
  attr_data_field :profile_authenticated  # boolean flag indicated that user authenticated has been provided for this transaction and stored payment information is available
  attr_data_field :dwolla_authenticated   # true when we've just authenticated to dwolla in the context of this transaction

  after_initialize :assign_uuid

  # todo: factor to ActiveRecord::Base

  # def assign_uuid
  #   self.uuid ||= SecureRandom.urlsafe_base64(8)
  # end
  #
  # def self.by_uuid(uuid)
  #   self.find_by(uuid: uuid)
  # end

  # def saved_payment_source(payment_type, autocreate: true)
  #   payment_source = payor.payment_source_for_type(payment_type, autocreate: true)
  # end

  #todo: automatically expose attributes via concern
  # def memo
  #   get_data_field(:memo)
  # end


  def amount
    paid_amount || base_amount
  end

  def recurrence_display
    if recurring_payment
      recurring_payment.interval_display
    elsif recurrence
      RecurringPayment.interval_display(recurrence)
    else
      nil
    end
  end

  def finished_url
    "#{base_url}/pay/#{embed.uuid}/thanks/#{uuid}"
  end

  def step2_url
    "#{base_url}/pay/#{embed.uuid}/step2/#{uuid}"
  end

  def address_url
    "#{base_url}/pay/#{embed.uuid}/address/#{uuid}"
  end


  def card_fee_range
    embed.card_payment_service.calculate_fee(self)
  end

  def card_fee_str
    low,high = card_fee_range
    "#{format_amount(low)}-#{format_amount(high)}"
  end


  def paypal_fee
    embed.paypal_service.calculate_fee(self)
  end

  def paypal_fee_str
    format_amount(embed.paypal_service.calculate_fee(self))
  end

  def payment_type_display
    payment_service_for_type(payment_type).payment_type_display  if payment_type
  end

  def completed
    status == 'completed'
  end

  def perform_payment(params = {})
    puts "perform payment - params: #{params}"
    if completed
      puts "warning, duplicate payment attempted for transaction: #{self.inspect}"
      raise "payment already complete (#{self.uuid})"
    end
    self.payment_type = (params[:payment_type] || self.payment_type)&.to_sym

    payment_service = payment_service_for_type(self.payment_type)

    fee = payment_service.calculate_fee(self, params)
    puts "estimated fee: #{fee.inspect}"
    if fee.is_a?(Array)
      puts "ERROR - unexpected fee range with final calculation"
      fee = fee.first.to_f
    end
    self.estimated_fee = fee
    self.allocated_fee = fee * Embed.allocation_ratio(self.fee_allocation)
    self.paid_amount = self.base_amount + allocated_fee
    self.save!

    #todo: cleanup. we don't need the fee as part of this result now
    #paid_amount,fee =
    payment_service.handle_payment(self, params)

    self.update!(
        status: 'completed',
        # allocated_fee: self.allocated_fee,
        # payment_type: self.payment_type,
        # paid_amount: self.paid_amount,
        # estimated_fee: self.estimated_fee
    )

    if self.recurrence.present?  #todo: make sure we don't get blanks strings assigned here
      recurring = RecurringPayment.create!(
          master_transaction: self,
          interval_units: self.recurrence,
          interval_count: 1,
          expires_date: nil,
          status: :active
      )
      self.update!(recurring_payment: recurring)
      recurring.increment_next_date
    end
    update_campaign
    TransactionAsyncCompletionJob.perform_async(self.id)
  end

  def submit_address(address_data)
    payor.submit_address(address_data)
    self.update!(address_captured: true)
  end

  def needs_address
    embed.capture_address.present?  && ! self.address_captured
  end


  def update_campaign
    if embed.campaign
      embed.campaign.apply_contribution(self)
      offer = resolve_offer
      if offer
        # puts "chosen offer: #{offer.uuid}"
        offer.allocate
      end
    end
  end

  def resolve_offer
    # offer_uuid = get_data_field(:offer_uuid)
    offer_uuid_val = offer_uuid
    if offer_uuid_val.present?
      puts "selected offer: #{offer_uuid_val}"
      Offer.resolve(offer_uuid_val)
    else
      nil
    end
  end

  def resolve_return_url
    result = return_url || embed.return_url
    correlation_id_val = correlation_id
    if result.present? && correlation_id_val.present?
      if result.include?('?')
        result += "&"
      else
        result += "?"
      end
      result += "correlation_id=#{correlation_id_val}"
    end
    result
  end

  #todo:, need to refactor rest of system to use this fee calc entry point
  def calculate_fee(params)
    self.payment_type = (params[:payment_type] || self.payment_type)&.to_sym
    payment_service = payment_service_for_type(self.payment_type)
    fee = payment_service.calculate_fee(self, params)
  end

  def fee_allocation_label
    embed.fee_allocation_label(fee_allocation, self)
  end

  def fee_allocation_label_merchant
    embed.fee_allocation_label_merchant(fee_allocation, self)
  end

  def fee_allocation_options
    embed.fee_allocation_options(self)
  end

  def async_completion
    puts "async completion - #{id}"
    send_receipts
    if mailing_list && mailing_list != 'false'
      puts "mailing lib subscribe - #{payor.email}"
      mailing_list_subscribe
    end

  end

  def send_receipts
    puts "send receipt - tran id: #{id}"
    PaymentNotifier.receipt(self).deliver_now
    PaymentNotifier.receipt_merchant(self).deliver_now
  end

  def mailing_list_subscribe
    service = embed.mailing_list_service
    if service
      service.subscribe(payor)
    else
      puts "warning mailing list service undefined"
    end
    #
    # mailchimp_list_id = ENV['MAILCHIMP_LIST_ID']
    # puts "list id: #{mailchimp_list_id}"
    # profile = payor
    #
    # gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
    #
    # #todo: double check if already subscribed first
    #
    # status = double_optin ? "pending" : "subscribed"
    # body = { email_address: profile.email, status: status, merge_fields: {FNAME: profile.first_name, LNAME: profile.last_name} }
    # gibbon.lists(mailchimp_list_id).members.create(body: body)
  end

  # def merchant_config_for_type(payment_type)
  #   result = payee.merchant_configs.find_by(kind: payment_type)
  #   raise "merchant config not found for payee: #{payee}, payment type: #{payment_type}"  unless result
  #   result
  # end

  def payment_service_for_type(payment_type)
    # merchant_config_for_type(payment_type).payment_service
    embed.payment_service_for_type(payment_type)
  end


  #
  # beware, the sendgrid templated version below not currently used.
  # not sure yet if sendgrid templates or actionmailer will be more convenient
  #

  def send_receipt_sendgrid
    mail = SendGrid::Mail.new do |m|
      m.to = payor.email
      m.from = 'system@fairpay.coop'
      m.subject = "Payment Receipt - #{payee.name}"
      m.html = ' '
      m.text = ' ' #receipt_body
    end

    # ADD THE SMTP API
    # The SendGrid Ruby Library has convenience
    # methods built in to take care of the SMTP-
    # API header for you.
    #===========================================#
    header = Smtpapi::Header.new

    # ADD THE SUBSTITUTION VALUES
    header.set_substitutions(
        {
            "%payor_name%" => [payor.name],
            "%payee_name%" => [payee.name],
            "%payee_email%" => [payee.email],
            "%paid_amount%" => [paid_amount.to_s],
            "%payment_type%" => [payment_type],
            "%transaction_fee%" => [estimated_fee.to_s],
            "%transaction_id%" => [id.to_s],
            "%status%" => [status],
        })

    template_id = ENV['SENDGRID_TEMPLATE_RECEIPT']

    # ADD THE APP FILTERS
    header.set_filters(
        {
            templates: {
                settings: {
                    enable: "1",
                    template_id: template_id
                }
            }
        })

    mail.smtpapi = header

    res = sendgrid_client.send(mail)
    puts res.code
    puts res.body
  end

#   def receipt_body
#     <<END
# Transaction id: #{id}
# Payor: #{payor.name}
# Payee: #{payee.name}, #{payee.email}
# Paid Amount: #{paid_amount}
# Payment Type: #{payment_type}
# Transaction Fee: #{estimated_fee}
# Status: #{status}
# END
#   end

  def sendgrid_client
    sendgrid_api_key = ENV['SENDGRID_API_KEY']
    client = SendGrid::Client.new(api_key: sendgrid_api_key)
  end


  def step2_data
    puts "step2_data"

    raise "missing transaction amount"  unless base_amount && base_amount > 0

    # current_user = resolve_current_user(session_data)
    # if current_user && current_user.email == payor.email
    #   puts "authenticated user session - stored payments available"
    #   # profile_authenticated = true
    #   authenticated_profile = current_user.profile
    #   address = authenticated_profile&.addresses&.first
    # # else
    # #   #todo: rip out once js session_data handling integrated
    # #   authenticated_profile = payor
    # end

    authenticated_profile = resolve_authenticated_profile
    address = authenticated_profile&.addresses&.first
    address ||= Address.new

    # used to resume after login
    # todo: think about this once devise auth integrated into widget
    # cookies[:current_url] = transaction.step2_url

    # payment_configs = embed.payment_configs.map do |merchant_config|
    #   merchant_config.payment_service.widget_data(self, session_data)
    # end

    result = {
        transaction: Transaction::Entity.represent(self),
        embed: Embed::Entity.represent(embed),  # note, not strictly needed by widget, but convenient for simple form flow
        authenticated_profile: Profile::Entity.represent(authenticated_profile),
        address: Address::Entity.represent(address),
        payment_configs: embed.payment_configs_data(self),
    }

    result[:redirect_url] = self.step2_url  # used by simple test flow
    result

  end

  def resolve_authenticated_profile
    if self.profile_authenticated
      payor
    else
      nil
    end
    # if session_data && session_data[:auth_token].present?
    #   user = User.find_by(auth_token: session_data[:auth_token])
    #   puts "auth token user: #{user}"
    #   user.profile
    # else
    #   nil
    # end
  end


  def next_step_url
    case next_step
      when :address
        self.address_url
      when :payment
        self.step2_url
      when :finished
        self.finished_url
    end
  end

  def next_step
    if completed
      :finished
    else
      if needs_address
        :address
      else
        :payment
      end
    end
  end

  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :uuid, :kind, :status, :base_amount, :paid_amount, :description, :offer_id, :recurrence, :recurrence_display
    expose :fee_allocation, :fee_allocation_label
    expose :fee_allocation_options
    expose :payee, using: Profile::Entity
    expose :payor, using: Profile::Entity
    expose :profile_authenticated
    expose :resolve_offer, using: Offer::Entity, as: :offer
    expose :needs_address
    expose :next_step
    # used by 'thanks' view
    expose :payment_type_display
    expose :memo, :estimated_fee
    expose :resolve_return_url, as: :return_url
    expose :recurring_payment, using: RecurringPayment::Entity

    #todo: figure out better way to automatically represent decimal values as json numbers
    def base_amount
      object.base_amount.to_f
    end
    def paid_amount
      object.paid_amount.to_f
    end
    def estimated_fee
      object.estimated_fee.to_f
    end
    # def paid_amount
    #   object.paid_amount.to_f
    # end

  end



end
