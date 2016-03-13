
class BaseCardService < BasePaymentService



  # which form partial to render for this payment type
  def form_partial
    'card'
  end

  def payment_type_display
    'Card'
  end

  def payment_type
    raise 'payment_type not implemented'
  end


  def handle_payment(transaction, params)
    use_payment_source = params[:use_payment_source].to_s == 'true'  #todo: better pattern here?
    save_payment_info = params[:save_payment_info].to_s == 'true'

    # charge_amount = transaction.amount

    # if use_payment_source
    #   payment_source = transaction.payor.payment_source_for_type(payment_type)
    unless use_payment_source
      puts "payment params: #{params.inspect}"

      # card_data = payment_data(transaction, params)

      if save_payment_info
        puts "will save payment info"
        number = params[:card_number]
        mmyy = params[:card_mmyy]
        bin = number[0..5]
        authorization_token = save_payment_info(transaction, params)
        payment_source = transaction.payor.payment_source_for_type(payment_type, autocreate: true)
        description = "...#{number[-4..-1]}, Exp: #{mmyy}"
        payment_source.set_data_field(:authorization_token, authorization_token)
        payment_source.set_data_field(:description, description)
        payment_source.set_data_field(:bin, bin)
        payment_source.save!
        use_payment_source = true
      else
        # puts "charge data: #{charge_data}"
        charge(transaction, params)
      end
    end
    if use_payment_source
      puts "using saved payment source"
      payment_source ||= transaction.payor.payment_source_for_type(payment_type)
      authorization_token = payment_source&.get_data_field(:authorization_token)
      purchase(transaction, authorization_token)
      raise StandardError, "missing customer_auth_token"  unless authorization_token
      transaction.update!(payment_source: payment_source)
    end

    # #todo: factor out the transaction update
    # transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)
    # transaction
    # [charge_amount, estimated_fee]
  end



  end