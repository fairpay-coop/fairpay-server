
class BasePaymentService


  def default_fee_config
    nil
  end

  def initialize_fee_service(merchant_config = nil)
    fee_config = merchant_config&.get_data_field(:fee) || default_fee_config
    @fee_service = FeeService.new(fee_config)
  end

  def fee_service
    @fee_service
  end

  def calculate_fee(amount, params = nil)
    @fee_service.calculate_fee(amount, params)
  end

  def estimate_fee(bin, amount)
    @fee_service.estimate_fee(bin, amount)
  end


  def supports_saved_payment_source
    false
  end

  def saved_payment_source(transaction, autocreate: true)
    if supports_saved_payment_source
      payment_source = transaction.payor.payment_source_for_type(payment_type, autocreate: autocreate)
    else
      nil
    end
  end


  def card_fee_str(transaction, params = nil)
    bin = nil
    if params.present? && params[:card_number].present?
      card = params[:card_number]
      bin = (card && card.length >= 6) ? card[0..5] : nil
    else
      saved = saved_payment_source(transaction)
      if saved
        bin = saved.get_data_field(:bin)
      end
    end
    result = fee_service.card_fee_str(transaction.base_amount, bin)
    puts "card fee str: #{result}"
    # low, high = payment_service.calculate_fee(transaction.base_amount, params)
    # result = "$#{format_amount(low)}"
    # if high  # we've been given a range
    #   result += "-#{format_amount(high)} (depends on card type)"
    # end
    result
  end


  # which form partial to render for this payment type
  def form_partial
    raise "form_partial not implemented for this payment service"
  end

  def payment_type_display
    raise "payment_type_display not implemented for this payment service"
  end

  def payment_type
    raise "payment_type not implemented for this payment service"
  end



end