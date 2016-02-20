require 'rubygems'
require 'yaml'
require 'authorizenet'


class AuthorizeNetService

  include AuthorizeNet::API


  def initialize(merchant_config)
    api_login_id = merchant_config.data['api_login_id']  #todo: use an indescriminant hash
    api_transaction_key = merchant_config.data['api_transaction_key']
    gateway = merchant_config.data['gateway']&.to_sym
    puts "api_login_id: #{api_login_id}"
    @transaction = AuthorizeNet::API::Transaction.new(api_login_id, api_transaction_key, :gateway => gateway)
  end


  def charge(data)
    request = CreateTransactionRequest.new

    request.transactionRequest = TransactionRequestType.new()
    request.transactionRequest.amount = data[:amount]
    request.transactionRequest.payment = PaymentType.new
    request.transactionRequest.payment.creditCard = CreditCardType.new(data[:card_number],data[:card_mmyy], data[:card_cvv])
    request.transactionRequest.transactionType = TransactionTypeEnum::AuthCaptureTransaction

    response = @transaction.create_transaction(request)

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


  def calculate_fee(amount, params = nil)
    unless params.present?
      Binbase.fee_range(amount)  # note, returns an array with low/high range when params are missing
    else
      card = params[:card_number]
      bin = card ? card[0..5] : nil
      data = estimate_fee(bin, amount)
      fee = data[:estimated_fee]
    end
  end


  def estimate_fee(bin, amount)
    Binbase.estimate_fee(bin, amount)
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