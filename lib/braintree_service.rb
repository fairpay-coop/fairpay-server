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


  def handle_payment(transaction, params)
    estimated_fee = calculate_fee(transaction.base_amount, params)
    charge_amount = transaction.base_amount

    # data = params.slice(:card_number, :card_mmyy, :card_cvv, :billing_zip)
    # data = params.slice(:card_number, :card_month, :card_year, :card_cvv, :billing_zip)
    #card_data = params.slice(:number, :month, :year, :verification_value, :billing_zip)
    mmyy = params[:card_mmyy]
    month = mmyy[0..1]
    year = "20#{mmyy[2..3]}"
    card_data = {
        first_name: transaction.payor.first_name,
        last_name: transaction.payor.last_name,
        number: params[:card_number],
        month: month,
        year: year,
        verification_value: params[:card_cvv]
    }

    # data[:amount] = paid_amount

    charge_data = {amount: charge_amount, card_data: card_data}
    puts "charge data: #{charge_data}"
    charge(charge_data)

    # #todo: factor out the transaction update
    # transaction.update!(status: 'completed', paid_amount: paid_amount, estimated_fee: estimated_fee)
    # transaction
    [charge_amount, estimated_fee]
  end

  def charge(data)
    credit_card = ActiveMerchant::Billing::CreditCard.new(data[:card_data])
    amount_cents = data[:amount] * 100

    # Validating the card automatically detects the card type
    if credit_card.validate.empty?
      response = @gateway.purchase(amount_cents, credit_card)

      if response.success?
        puts "Successfully charged $#{sprintf("%.2f", amount_cents / 100)} to the credit card #{credit_card.display_number}"
      else
        raise StandardError, response.message
      end
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