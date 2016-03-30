
class BasePaymentService
  include ApplicationHelper

  def default_fee_config
    nil
  end

  def initialize_fee_service(merchant_config = nil)
    fee_config = merchant_config&.get_data_field(:fee) || default_fee_config
    @fee_service = FeeService.new(fee_config, self)
  end

  def fee_service
    @fee_service
  end

  def calculate_fee(transaction, params = nil)
    @fee_service.calculate_fee(transaction, params)
  end

  def estimate_fee(amount, bin = nil)
    @fee_service.estimate_fee(amount, bin)
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
      saved = saved_payment_source(transaction, autocreate:false)
      if saved
        bin = saved.get_data_field(:bin)
      end
    end
    result = fee_service.card_fee_str(transaction, bin)
    puts "card fee str: #{result}"
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


    def widget_data(transaction)
      result = {
          # kind: kind,
          label: payment_type_display,
          fee_update_enabled: fee_service.fee_update_enabled,
          supports_saved_payment_source: supports_saved_payment_source,
      }
      result[:card_fee_str] = card_fee_str(transaction)  if transaction
      result
  end


end