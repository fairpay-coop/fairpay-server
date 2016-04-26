require 'rubygems'
require 'yaml'
require 'authorizenet'


class AuthorizeNetService  < BaseCardService

  include AuthorizeNet::API


  def initialize(merchant_config)
    api_login_id = merchant_config.get_data_field(:api_login_id)
    api_transaction_key = merchant_config.get_data_field(:api_transaction_key)
    gateway_flag = merchant_config.get_data_field(:gateway)&.to_sym  # sandbox vs prod
    puts "api_login_id: #{api_login_id}"
    @gateway = AuthorizeNet::API::Transaction.new(api_login_id, api_transaction_key, :gateway => gateway_flag)

    initialize_fee_service(merchant_config)
  end



  def payment_type
    :authorizenet
  end

  #todo: implement custom or get auth.net activemerchant to properly work
  def supports_saved_payment_source
    true
  end

  # def handle_payment(transaction, params)
  #   estimated_fee = calculate_fee(transaction, params)
  #   paid_amount = transaction.base_amount
  #
  #   data = params.slice(:card_number, :card_mmyy, :card_cvv, :billing_zip)
  #   data[:amount] = paid_amount
  #   puts "data: #{data}"
  #
  #   charge(data)
  #
  #   # #todo: factor out the transaction update
  #   # transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)
  #   # transaction
  #   [paid_amount, estimated_fee]
  # end

  def payment_data(transaction, params)
    data = params.slice(:card_number, :card_mmyy, :card_cvv, :billing_zip)
    puts "auth net payment data: #{data}"
    data
  end

  def charge(transaction, data)
    raise "billing zip required"  unless data[:billing_zip]

    request = CreateTransactionRequest.new

    amount = transaction.amount
    request.transactionRequest = TransactionRequestType.new()
    request.transactionRequest.amount = amount
    request.transactionRequest.payment = PaymentType.new
    request.transactionRequest.payment_raw.creditCard = credit_card_type(data)
    request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction

    response = @gateway.create_transaction(request)

    if response.messages.resultCode == MessageTypeEnum::Ok
      puts "Successful charge (auth + capture) (authorization code: #{response.transactionResponse.authCode})"

    else
      result_data = {result_code: response.messages.resultCode, result_text: response.messages.messages[0].text}
      if response.transactionResponse && response.transactionResponse.errors
        result_data[:error_code] = response.transactionResponse.errors.errors[0].errorCode
        result_data[:error_text] = response.transactionResponse.errors.errors[0].errorText
      end
      puts "failure - result data: #{result_data}"
      message = result_data[:error_text] || result_data[:result_text]
      # todo: custom error class which can hold the full result data
      raise message
    end

  end

  def credit_card_type(data)
    result = CreditCardType.new(data[:card_number],data[:card_mmyy], data[:card_cvv])
    puts("credit card type for data: #{data.inspect} -> #{data.inspect}")
    result
  end


  def save_payment_info(transaction, card_data)

    request = CreateCustomerProfileRequest.new
    payor = transaction.payor
    request.profile = CustomerProfileType.new(payor.id, payor.name, payor.email, nil, nil)  #todo better customer profile id

    customer_profile_id = payor.get_data_field(:authorizenet_customer_profile_id)
    unless customer_profile_id
      response = @gateway.create_customer_profile(request)
      if response.messages.resultCode == MessageTypeEnum::Ok
        puts "Successfully created a customer profile with id:  #{response.customerProfileId}"
      else
        puts response.messages.messages[0].text
        raise "Failed to create a new customer profile."
      end

      customer_profile_id = response.customerProfileId
      payor.update_data_field(:authorizenet_customer_profile_id, customer_profile_id)
    end


    request = CreateCustomerPaymentProfileRequest.new

    payment = PaymentType.new( credit_card_type(card_data) )
    profile = CustomerPaymentProfileType.new(nil,nil,payment,nil,nil)

    request.paymentProfile = profile
    request.customerProfileId = customer_profile_id
    response = @gateway.create_customer_payment_profile(request)

    if response.messages.resultCode == MessageTypeEnum::Ok
      puts "Successfully created a customer payment profile with id:  #{response.customerPaymentProfileId}"
      response.customerPaymentProfileId
    else
      puts "Failed to create a new customer payment profile: #{response.messages.messages[0].text}"
      raise "Failed to create a new customer payment profile: #{response.messages.messages[0].text}"  #todo: could make this not fatal
    end

  end


  def purchase(transaction, authorization_token)
    request = CreateTransactionRequest.new
    payor = transaction.payor

    request.transactionRequest = TransactionRequestType.new()
    request.transactionRequest.amount = transaction.amount
    request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction
    request.transactionRequest.profile = CustomerProfilePaymentType.new()
    request.transactionRequest.profile.customerProfileId = payor.get_data_field(:authorizenet_customer_profile_id)
    request.transactionRequest.profile.paymentProfile = PaymentProfile.new(authorization_token)

    puts("customerProfileId: #{payor.get_data_field(:authorizenet_customer_profile_id)}, auth token: #{authorization_token}")
    puts("profile payment request: #{request.inspect}")

    response = @gateway.create_transaction(request)

    if response.messages.resultCode == MessageTypeEnum::Ok
      if response.transactionResponse != nil
        puts "Success, Auth Code : #{response.transactionResponse.authCode}"
      end
    else
      puts response.messages.messages[0].text
      raise "Failed to charge customer profile."
    end
  end

end