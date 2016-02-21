class PaypalService

  DEFAULT_CONFIG = {
      mode: ENV['PAYPAL_MODE'],
      username: ENV['PAYPAL_API_USERNAME'],
      password: ENV['PAYPAL_API_PASSWORD'],
      signature: ENV['PAYPAL_API_SIGNATURE']
  }


  def initialize(merchant_config = DEFAULT_CONFIG)
    @config = merchant_config
    @api = PayPal::SDK::Merchant.new(nil, merchant_config)

    #
    # api_login_id = merchant_config.data['api_login_id']  #todo: use an indescriminant hash
    # api_transaction_key = merchant_config.data['api_transaction_key']
    # gateway = merchant_config.data['gateway']&.to_sym
    # puts "api_login_id: #{api_login_id}"
    # @transaction = AuthorizeNet::API::Transaction.new(api_login_id, api_transaction_key, :gateway => gateway)
    #
    # PayPal::SDK.configure(
    #     mode:   ENV['PAYPAL_MODE'],
    #     # app_id doesn't seem to be required, and i can't find value in my paypal admin panel
    #     # app_id: ENV['PAYPAL_APP_ID'],
    #     username: ENV['PAYPAL_API_USERNAME'],
    #     password: ENV['PAYPAL_API_PASSWORD'],
    #     signature: ENV['PAYPAL_API_SIGNATURE'],
    #     # token: ENV['PAYPAY_TOKEN'],
    #     # token_secret: ENV['PAYPAL_TOKEN_SECRET'],
    #     http_timeout: 30
    # )
    # @api = PayPal::SDK::Merchant.new()
    #

  end

  def api
    @api
  end

  def base_url
    @base_url || ENV['BASE_URL']
  end

  # def return_url(transaction_uuid)
  #   "#{base_url}/paypal/complete_payment?t=#{transaction_uuid}"
  # end
  #
  # def cancel_url
  #   base_url
  # end

  def express_checkout(amount, return_url, cancel_url)

    # # Notify url
    # pay.NotifyURL ||= ipn_notify_url
    #
    set_express_checkout = @api.build_set_express_checkout(
        {
            :SetExpressCheckoutRequestDetails => {
                :ReturnURL => return_url,
                :CancelURL => cancel_url,   #todo: need a better return url
                :PaymentDetails =>
                    [{
                         :OrderTotal => {:value => amount},
                         :ItemTotal => {:value => amount},
                         :ButtonSource => "PayPal_SDK",
                         # :NotifyURL => "http://local.fairpay.coop:3000/samples/merchant/ipn_notify",
                         :PaymentDetailsItem => [{:Amount => {:value => amount}}]
                     }]
            }
        }
    )


    # Make API call & get response
    set_express_checkout_response = @api.set_express_checkout(set_express_checkout)

    # Access Response
    if set_express_checkout_response.success?
      token = set_express_checkout_response.Token
      puts "success token: #{token}"
      express_checkout_url = @api.express_checkout_url(set_express_checkout_response)
      puts "checkout url: #{express_checkout_url}"
      {status: :success, checkout_url: express_checkout_url}

    else
      errors = set_express_checkout_response.Errors
      puts "errors: #{errors}"
      {status: :error, errors: errors}
    end

  end



  def complete_payment(token, payer_id, amount)
    # token = params[:token]
    # payer_id = params[:PayerID]
    # amount = session[:amount]


    do_express_checkout_payment = @api.build_do_express_checkout_payment(
        {
            :DoExpressCheckoutPaymentRequestDetails => {
                :PaymentAction => "Sale",
                :Token => token,
                :PayerID => payer_id,
                :PaymentDetails =>
                    [{
                         :OrderTotal => {:value => amount},
                         :ButtonSource => "PayPal_SDK",
                         # :NotifyURL => "http://local.fairpay.coop:3000/samples/merchant/ipn_notify"
                     }],
                :ButtonSource => "PayPal_SDK" }
        }
    )

# Make API call & get response
    do_express_checkout_payment_response = @api.do_express_checkout_payment(do_express_checkout_payment)

# Access Response
    if do_express_checkout_payment_response.success?
      response_details = do_express_checkout_payment_response.DoExpressCheckoutPaymentResponseDetails
      puts "response details: #{response_details}"
      puts "fmf details: #{do_express_checkout_payment_response.FMFDetails}"
      # not sure what the object inteface is, so convert into hash data
      data = JSON.parse(response_details.to_json)
      puts "hashed response data: #{data}"
      gross_amount = data['ebl:PaymentInfo'][0]['ebl:GrossAmount']['value']
      fee_amount = data['ebl:PaymentInfo'][0]['ebl:FeeAmount']['value']
      {status: :success, gross_amount: gross_amount, fee_amount: fee_amount}
    else
      errors = do_express_checkout_payment_response.Errors
      puts "errors: #{errors}"
      {status: :error, errors: errors}
    end


  end

  def calculate_fee(amount, params = nil)
    Binbase.apply_fee_rate(amount, 0.30, 2.9)
  end



end