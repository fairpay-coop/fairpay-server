
class ActiveMerchantService < BaseCardService


  def initialize(merchant_config)
    mode = (merchant_config.get_data_field(:mode) || :production).to_sym
    ActiveMerchant::Billing::Base.mode = mode
    # ActiveMerchant::Billing::Base.mode = :test

    initialize_gateway(merchant_config)
    initialize_fee_service(merchant_config)
  end

  def initialize_gateway(merchant_config)
    # for now, contructor hardwired to authorize.net
    # todo: dynamic initializer hanadling
    gateway_params = merchant_config.indifferent_data.slice(:login, :password)
    # gateway_params[:test] = true

    @gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(gateway_params)

  end


  def payment_type
    :activemerchant
  end


  def supports_saved_payment_source
    true
  end

  # inherited from BaseCardService
  # def handle_payment(transaction, params)


  def payment_data(transaction, params)
    number = params[:card_number]
    raise "'card_number' param missing"  unless number
    mmyy = params[:card_mmyy]
    month = mmyy[0..1]
    year = "20#{mmyy[2..3]}"
    card_data = {
        first_name: transaction.payor.resolve_first_name,
        last_name: transaction.payor.resolve_last_name,
        number: number,
        month: month,
        year: year,
        verification_value: params[:card_cvv],
        #billing_zip: params[:billing_zip]
    }
  end

  def charge(transaction, params)
    card_data = payment_data(transaction, params)
    options = {billing_address: {zip: params[:billing_zip]}}

    credit_card = ActiveMerchant::Billing::CreditCard.new(card_data)
    amount_cents = (transaction.amount * 100).to_i

    # Validating the card automatically detects the card type
    if credit_card.validate.empty?
      response = @gateway.purchase(amount_cents, credit_card, options)

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

  def purchase(transaction, authorization_token)   # todo: finish partial refactoring to remove separate amount & vault params
    amount_cents = (transaction.amount * 100).to_i
    response = @gateway.purchase(amount_cents, authorization_token)
    puts "purchase response: #{response.inspect}"
    if response.success?
      puts "Successfully charged stored card info - #{response.message}"
    else
      raise StandardError, response.message
    end
  end

  def save_payment_info(transaction, params)
    card_data = payment_data(transaction, params)
    credit_card = ActiveMerchant::Billing::CreditCard.new(card_data)

    # factor this with above
    if credit_card.validate.empty?
      response = @gateway.store(credit_card)
      puts "response: #{response.inspect}"
      if response.success?
        authorization_token = response.authorization
        puts "authorization: #{authorization_token}"
        authorization_token
      else
        raise StandardError, response.message
      end
    else
      errors = credit_card.validate.inspect
      puts "validate errors: #{errors}"
      raise StandardError, errors
    end
  end



end