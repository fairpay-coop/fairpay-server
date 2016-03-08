class MerchantConfig < ActiveRecord::Base
  include DataFieldable


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
    # bin = nil
    # if params.present? && params[:card_number].present?
    #   card = params[:card_number]
    #   bin = (card && card.length >= 6) ? card[0..5] : nil
    # else
    #   saved = payment_service.saved_payment_source(transaction)
    #   if saved
    #     bin = saved.get_data_field(:bin)
    #   end
    # end
    # result = payment_service.fee_service.card_fee_str(transaction.base_amount, bin)
    # puts "card fee str: #{result}"
    # # low, high = payment_service.calculate_fee(transaction.base_amount, params)
    # # result = "$#{format_amount(low)}"
    # # if high  # we've been given a range
    # #   result += "-#{format_amount(high)} (depends on card type)"
    # # end
    # result
  end

  # def card_fee_range
  #   embed.card_payment_service.calculate_fee(base_amount)
  # end
  #
  # def card_fee_str
  #   low,high = card_fee_range
  #   "#{format_amount(low)}-#{format_amount(high)}"
  # end

  def format_amount(amount)
    '%.2f' % amount
  end


end
