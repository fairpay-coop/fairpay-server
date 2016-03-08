
class BaseCardService < BasePaymentService


  # def initialize_fee_service(merchant_config)
  #   fee_config = merchant_config.get_data_field(:fee)
  #   @fee_service = FeeService.new(fee_config)
  # end
  #
  # def fee_service
  #   @fee_service
  # end
  #
  # # factor this out to a concern
  # def calculate_fee(amount, params = nil)
  #   @fee_service.calculate_fee(amount, params)
  # end
  #
  # def estimate_fee(bin, amount)
  #   @fee_service.estimate_fee(bin, amount)
  # end
  #
  #
  # def supports_saved_payment_source
  #   false
  # end
  #
  # def saved_payment_source(transaction, autocreate: true)
  #   if supports_saved_payment_source
  #     payment_source = transaction.payor.payment_source_for_type(payment_type, autocreate: autocreate)
  #   else
  #     nil
  #   end
  # end
  #
  #
  # def card_fee_str(transaction, params = nil)
  #   bin = nil
  #   if params.present? && params[:card_number].present?
  #     card = params[:card_number]
  #     bin = (card && card.length >= 6) ? card[0..5] : nil
  #   else
  #     saved = saved_payment_source(transaction)
  #     if saved
  #       bin = saved.get_data_field(:bin)
  #     end
  #   end
  #   result = fee_service.card_fee_str(transaction.base_amount, bin)
  #   puts "card fee str: #{result}"
  #   # low, high = payment_service.calculate_fee(transaction.base_amount, params)
  #   # result = "$#{format_amount(low)}"
  #   # if high  # we've been given a range
  #   #   result += "-#{format_amount(high)} (depends on card type)"
  #   # end
  #   result
  # end


  # which form partial to render for this payment type
  def form_partial
    'card'
  end

  def payment_type_display
    'Card'
  end


  def handle_payment(transaction, params)
    use_payment_source = params[:use_payment_source].to_s == 'true'  #todo: better pattern here?
    save_payment_info = params[:save_payment_info].to_s == 'true'

    if use_payment_source
      payment_source = transaction.payor.payment_source_for_type(payment_type)
      bin = payment_source&.get_data_field(:bin)
      params[:card_number] = bin
    end

    estimated_fee = calculate_fee(transaction.base_amount, params)
    charge_amount = transaction.base_amount

    unless use_payment_source
      puts "payment params: #{params.inspect}"

      number = params[:card_number]
      raise "'card_number' param missing"  unless number
      bin = number[0..5]
      mmyy = params[:card_mmyy]
      month = mmyy[0..1]
      year = "20#{mmyy[2..3]}"
      card_data = {
          first_name: transaction.payor.first_name,
          last_name: transaction.payor.last_name,
          number: number,
          month: month,
          year: year,
          verification_value: params[:card_cvv]
      }

      if save_payment_info
        puts "will save payment info"
        authorization_token = save_payment_info(card_data)
        payment_source = transaction.payor.payment_source_for_type(payment_type, autocreate: true)
        description = "...#{number[-4..-1]}, Exp: #{mmyy}"
        payment_source.set_data_field(:authorization_token, authorization_token)
        payment_source.set_data_field(:description, description)
        payment_source.set_data_field(:bin, bin)
        payment_source.save!
        use_payment_source = true
      else
        # puts "charge data: #{charge_data}"
        charge(charge_amount, card_data)
      end
    end
    if use_payment_source
      puts "using saved payment source"
      payment_source ||= transaction.payor.payment_source_for_type(payment_type)
      authorization_token = payment_source&.get_data_field(:authorization_token)
      purchase(charge_amount, authorization_token)
      raise StandardError, "missing customer_auth_token"  unless authorization_token
      transaction.update!(payment_source: payment_source)
    end

    # #todo: factor out the transaction update
    # transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)
    # transaction
    [charge_amount, estimated_fee]
  end



end