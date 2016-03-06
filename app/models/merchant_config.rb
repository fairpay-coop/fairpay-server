class MerchantConfig < ActiveRecord::Base
  include DataFieldable


  # create_table :merchant_configs do |t|
  #   t.references :profile, index: true, foreign_key: true
  #   t.string :kind
  #   t.json :data
  #   t.timestamps null: false

  belongs_to :profile


  KINDS = {stripe: 'Stripe', authorizenet: 'Authorize.Net', braintree: 'Braintree', dwolla: 'Dwolla', paypal: 'PayPal'}

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
      when :paypal
        PaypalService.new(data)
      else
        raise "service type: #{kind} - not yet implemented"
    end
  end


  def saved_payment_source(transaction, autocreate: true)
    payment_source = transaction.payor.payment_source_for_type(payment_type, autocreate: autocreate)
  end



  # def form_name
  #   payment_service.form_name
  # end

  # consider factoring out to payment service
  def form_name
    if kind_sym == :authorizenet || kind_sym == :braintree
      'card'
    else
      kind
    end
  end

  # consider factoring out to payment service
  def fee_update_enabled
    if kind_sym == :authorizenet
      true
    else
      false
    end
  end

  def card_fee_str(transaction, params = nil)
    low, high = payment_service.calculate_fee(transaction.base_amount, params)
    result = "$#{format_amount(low)}"
    if high  # we've been given a range
      result += "-#{format_amount(high)} (depends on card type)"
    end
    result
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
