class Transaction < ActiveRecord::Base
  include UuidAssignable
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
  #   t.decimal :allocated_fee
  #   t.decimal :platform_fee
  #   t.decimal :paid_amount
  #   t.string :description
  #   t.json :data
  #   t.string :fee_allocation  : payee, split, payor
  #   t.string :recurrence
  #   t.reference :recurring_payment, index: true, foreign_key: true
  #   t.timestamps null: false
  #   t.strting :payment_type
  #   t.string :mailing_list


  belongs_to :payor, class_name: 'Profile'
  belongs_to :payee, class_name: 'Profile'
  belongs_to :embed
  belongs_to :payment_source
  belongs_to :merchant_config
  belongs_to :recurring_payment

  # not yet used - but likely to be useful for cases like a refund
  belongs_to :parent, class_name: 'Transaction'


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


  def card_fee_range
    embed.card_payment_service.calculate_fee(self)
  end

  def card_fee_str
    low,high = card_fee_range
    "#{format_amount(low)}-#{format_amount(high)}"
  end

  def format_amount(amount)
    '%.2f' % amount
  end

  def paypal_fee
    embed.paypal_service.calculate_fee(self)
  end

  def paypal_fee_str
    format_amount(embed.paypal_service.calculate_fee(self))
  end

  def payment_type_display
    payment_service_for_type(payment_type).payment_type_display
  end

  def perform_payment(params = {})
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

    if self.recurrence
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
    TransactionAsyncCompletionJob.perform_async(self.id)
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

  def async_completion
    puts "async completion - #{id}"
    send_receipts
    if mailing_list
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

  def merchant_config_for_type(payment_type)
    result = payee.merchant_configs.find_by(kind: payment_type)
    raise "merchant config not found for payee: #{payee}, payment type: #{payment_type}"  unless result
    result
  end

  def payment_service_for_type(payment_type)
    merchant_config_for_type(payment_type).payment_service
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

end
