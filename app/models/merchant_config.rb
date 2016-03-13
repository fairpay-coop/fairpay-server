class MerchantConfig < ActiveRecord::Base
  include DataFieldable
  include ApplicationHelper   # had been used for format_amount


  # create_table :merchant_configs do |t|
  #   t.references :profile, index: true, foreign_key: true
  #   t.string :kind
  #   t.json :data
  #   t.timestamps null: false
  # add_column :merchant_configs, :name, :string
  # add_column :merchant_configs, :internal_name, :string

  belongs_to :profile


  KINDS = {
      stripe: 'Stripe',
      authorizenet: 'Authorize.Net',
      braintree: 'Braintree',
      active_merchant: 'Active Merchant',
      dwolla: 'Dwolla',
      paypal: 'PayPal',
      mailchimp: 'MailChimp'
  }

  def self.kinds
    KINDS
  end

  def kind_name
    KINDS[kind_sym]
  end

  def payment_type
    kind_sym
  end

  def kind_sym
    kind.to_sym
  end

  #todo: memoize this result?
  def payment_service
    case kind_sym
      when :dwolla
        DwollaService.instance
      when :authorizenet
        AuthorizeNetService.new(self)
      when :braintree
        BraintreeService.new(self)
      when :active_merchant
        ActiveMerchantService.new(self)
      when :paypal
        PaypalService.new(data)
      when :mailchimp
        MailchimpService.new(self)
      else
        raise "service type: #{kind} - not yet implemented"
    end
  end

  alias_method :service, :payment_service



  # def saved_payment_source(transaction, autocreate: true)
  #   payment_source = transaction.payor.payment_source_for_type(payment_type, autocreate: autocreate)
  # end


  # def form_name
  #   payment_service.form_name
  # end

  # todo: can now be refactored
  def form_name
    card? ? 'card' : kind
  end

  def card?
    # todo: this caan potentially be refactored now with service api
    kind_sym == :authorizenet || kind_sym == :braintree || kind_sym == :active_merchant
  end



  # consider factoring out to payment service base class
  def fee_update_enabled
    payment_service.fee_service.fee_update_enabled
  end

  #todo: need a better place to factor shared payment service logic too, probably a base class
  def card_fee_str(transaction, params = nil)
    payment_service.card_fee_str(transaction, params)
  end


end
