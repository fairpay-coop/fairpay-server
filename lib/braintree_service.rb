require 'active_merchant'

class BraintreeService

  # example merchant config:
  #   {merchant_id: 'X', public_key: 'Y', private_key: 'Z', mode: 'test'}

  def initialize(merchant_config)

    # valid modes: :test, :production
    mode = (merchant_config.get_data_field(:mode) || :production).to_sym
    ActiveMerchant::Billing::Base.mode = mode

    gateway_params = merchant_config.indifferent_data.slice(:merchant_id, :public_key, :private_key)
    @gateway = ActiveMerchant::Billing::BraintreeGateway.new(gateway_params)

  end


  # which form partial to render for this payment type
  def form_partial
    'card'
  end

  def payment_type
    :braintree
  end


  def handle_payment(transaction, params)
    estimated_fee = calculate_fee(transaction.base_amount, params)
    charge_amount = transaction.base_amount

    # data = params.slice(:card_number, :card_mmyy, :card_cvv, :billing_zip)
    # data = params.slice(:card_number, :card_month, :card_year, :card_cvv, :billing_zip)
    #card_data = params.slice(:number, :month, :year, :verification_value, :billing_zip)

    use_payment_source = params[:use_payment_source] == 'true'  #todo: better pattern here?
    unless use_payment_source
      number = params[:card_number];
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

      if params[:save_payment_info]
        puts "will save payment info"
        vault_id = save_payment_info(card_data)
        payment_source = transaction.payor.payment_source_for_type(payment_type, autocreate: true)
        description = "...#{number[-4..-1]}, Exp: #{mmyy}"
        payment_source.set_data_field(:customer_vault_id, vault_id)
        payment_source.set_data_field(:description, description)
        payment_source.save!
        use_payment_source = true
      else
        # charge_data = {amount: charge_amount, card_data: card_data}
        # puts "charge data: #{charge_data}"
        charge(charge_amount, card_data)
      end
    end
    if use_payment_source
      puts "using saved payment source"
      payment_source ||= transaction.payor.payment_source_for_type(payment_type)
      customer_vault_id = payment_source&.get_data_field(:customer_vault_id)
      purchase(charge_amount, customer_vault_id)
      raise StandardError, "missing customer_vault_id"  unless customer_vault_id
      transaction.update!(payment_source: payment_source)
    end

    # #todo: factor out the transaction update
    # transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)
    # transaction
    [charge_amount, estimated_fee]
  end

  def charge(amount, card_data)
    credit_card = ActiveMerchant::Billing::CreditCard.new(card_data)
    amount_cents = amount * 100

    # Validating the card automatically detects the card type
    if credit_card.validate.empty?
      response = @gateway.purchase(amount_cents, credit_card)

      if response.success?
        puts "Successfully charged $#{sprintf("%.2f", amount_cents / 100)} to the card #{credit_card.display_number}"
      else
        raise StandardError, response.message
      end
    else
      errors = credit_card.validate.inspect
      puts "validate errors: #{errors}"
      raise StandardError, errors
    end
  end

  def purchase(amount, customer_vault_id)
    amount_cents = amount * 100
    response = @gateway.purchase(amount_cents, customer_vault_id)
    puts "purchase response: #{response.inspect}"
    if response.success?
      puts "Successfully charged stored card info - #{response.message}"
    else
      raise StandardError, response.message
    end
  end

  def save_payment_info(card_data)
    credit_card = ActiveMerchant::Billing::CreditCard.new(card_data)

    # factor this with above
    if credit_card.validate.empty?
      response = @gateway.store(credit_card)
      puts "response: #{response.inspect}"
      if response.success?
        vault_id = response.params["customer_vault_id"]
        puts "Successfully stored card info: #{credit_card.display_number} - vault_id: #{vault_id}"
        vault_id
      else
        raise StandardError, response.message
      end
    else
      errors = credit_card.validate.inspect
      puts "validate errors: #{errors}"
      raise StandardError, errors
    end
  end


  def calculate_fee(amount, params = nil)
    Binbase.apply_fee_rate(amount, 0.30, 2.9)
  end



  # def create_customer_profile
  #   transaction = authorizenet_transaction
  #
  #   request = GetCustomerPaymentProfileRequest.new
  #   request.customerProfileId = '36152115'
  #   request.customerPaymentProfileId = '32689262'
  #
  #   response = transaction.get_customer_payment_profile(request)
  #
  #   if response.messages.resultCode == MessageTypeEnum::Ok
  #     puts "Successfully retrieved a payment profile with profile id is #{request.customerPaymentProfileId} and whose customer id is #{request.customerProfileId}"
  #     puts "First name in billing address: #{response.paymentProfile.billTo.firstName}"
  #     puts "Masked Credit card number: #{response.paymentProfile.payment.creditCard.cardNumber}"
  #   else
  #     puts response.messages.messages[0].text
  #     raise "Failed to get payment profile information with id #{request.customerPaymentProfileId}"
  #   end
  # end

end