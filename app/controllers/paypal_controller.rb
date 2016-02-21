class PaypalController < ApplicationController

  include PayPal::SDK::Merchant


  def checkout
    amount = params[:amount]

    session[:amount] = amount

    # # Notify url
    # pay.NotifyURL ||= ipn_notify_url
    #
    # # Return and cancel url
    # details.ReturnURL ||= merchant_url(:do_express_checkout_payment)
    # details.CancelURL ||= merchant_url(:set_express_checkout)

    set_express_checkout = api.build_set_express_checkout(
        {
            :SetExpressCheckoutRequestDetails => {
                :ReturnURL => paypal_complete_payment_url,
                :CancelURL => root_url,
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
    set_express_checkout_response = api.set_express_checkout(set_express_checkout)

# Access Response
    if set_express_checkout_response.success?
      token = set_express_checkout_response.Token
      puts "success token: #{token}"
      express_checkout_url = api.express_checkout_url(set_express_checkout_response)
      puts "checkout url: #{express_checkout_url}"
      redirect_to express_checkout_url

    else
      errors = set_express_checkout_response.Errors
      puts "errors: #{errors}"
      render json: errors
    end

  end

  def complete_payment
    token = params[:token]
    payer_id = params[:PayerID]

    amount = session[:amount]


    do_express_checkout_payment = api.build_do_express_checkout_payment(
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
    do_express_checkout_payment_response = api.do_express_checkout_payment(do_express_checkout_payment)

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
      render json: {status: 'success', gross_amount: gross_amount, fee_amount: fee_amount}
    else
      errors = do_express_checkout_payment_response.Errors
      puts "errors: #{errors}"
      render json: {errors: errors}
    end


  end


  # def get_express_checkout_details
  #   @get_express_checkout_details = api.build_get_express_checkout_details(params[:GetExpressCheckoutDetailsRequestType] || default_api_value)
  #   @get_express_checkout_details_response = api.get_express_checkout_details(@get_express_checkout_details) if request.post?
  # end



  def default_api_value
    t("#{service_name}.#{service_action}", :default => {})
  end

  private

  def api
    @api ||= API.new
  end

end