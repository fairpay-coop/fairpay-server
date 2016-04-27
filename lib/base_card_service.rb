
class BaseCardService < BasePaymentService



  # which form partial to render for this payment type
  def form_partial
    'card'
  end

  def payment_type_display
    #'Card'
    "Debit/Credit Card"
  end

  def payment_type
    raise 'payment_type not implemented'
  end


  def handle_payment(transaction, params)
    use_payment_source = params[:use_payment_source].to_s == 'true'  #todo: better pattern here?
    save_payment_info = params[:save_payment_info].to_s == 'true'
    card_mmyy = to_mmyy(params[:card_mmyy])
    puts("mmyy: #{card_mmyy}")
    params[:card_mmyy] = card_mmyy
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

  # normalizes a 'mm/yy[yy]' string into 'mmyy'
  def to_mmyy(value)
    parts = value.split('/')
    if parts.size != 2
      value
    else
      mm = parts[0].rjust(2,'0')
      yy = parts[1].length <= 2 ? parts[1] : parts[1][-2..-1]
      mm+yy
    end
  end

  def widget_data(transaction)
    # result = {
    #     label: 'Debit/Credit Card', # (#{merchant_config.kind_name})'
    #     card_fee_str: card_fee_str(transaction),
    #     fee_update_enabled: fee_service.fee_update_enabled,
    #     supports_saved_payment_source: supports_saved_payment_source,
    # }
    result = super(transaction)
    if transaction
      payment_source = saved_payment_source(transaction, autocreate:false)

      if payment_source
        result[:saved_payment_source] = payment_source.represent #&.get_data_field(:description)
      end
    end

    result
  end


end