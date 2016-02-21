class PaypalController < ApplicationController

  include PayPal::SDK::Merchant


  def checkout

    transaction_uuid = params[:t]
    puts "t uuid: #{transaction_uuid}"
    transaction = Transaction.by_uuid(transaction_uuid)

    amount = transaction.base_amount

    # better way to add query params to an url?
    return_url = "#{paypal_complete_payment_url}?t=#{transaction_uuid}"
    cancel_url = "#{root_url}/pay/#{transaction.embed.uuid}/step2/#{transaction_uuid}"
    puts "return url: #{return_url}, cancel_url: #{cancel_url}"

    paypal_service = transaction.embed.paypal_service
    raise "paypal config not found for embed: #{transaction.embed.uuid}"  unless paypal_service
    data = paypal_service.express_checkout(amount, return_url, cancel_url)

    if data[:status] == :success
      redirect_to data[:checkout_url]
    else
      render json: data
    end

  end

  def complete_payment
    token = params[:token]
    payer_id = params[:PayerID]

    transaction_uuid = params[:t]
    puts "t uuid: #{transaction_uuid}, token: #{token}, payer_id: #{payer_id}"
    transaction = Transaction.by_uuid(transaction_uuid)
    raise "transaction not found for uuid: #{transaction_uuid}"  unless transaction
    embed = transaction.embed

    data = {
        transaction_uuid: transaction_uuid,
        payment_type: :paypal,
        token: token,
        payer_id: payer_id
    }
    embed.step2(data)

    redirect_to "/pay/#{embed.uuid}/thanks/#{transaction.uuid}"

#
#     amount = transaction.base_amount
#
#     paypal_service = transaction.embed.paypal_service
#     raise "paypal config not found for embed: #{transaction.embed.uuid}"
#     data = paypal_service.complete_payment(token, payer_id, amount)
#
#     amount = session[:amount]
#
#
#     do_express_checkout_payment = api.build_do_express_checkout_payment(
#         {
#             :DoExpressCheckoutPaymentRequestDetails => {
#                 :PaymentAction => "Sale",
#                 :Token => token,
#                 :PayerID => payer_id,
#                 :PaymentDetails =>
#                     [{
#                          :OrderTotal => {:value => amount},
#                          :ButtonSource => "PayPal_SDK",
#                          # :NotifyURL => "http://local.fairpay.coop:3000/samples/merchant/ipn_notify"
#                      }],
#                 :ButtonSource => "PayPal_SDK" }
#         }
#     )
#
# # Make API call & get response
#     do_express_checkout_payment_response = api.do_express_checkout_payment(do_express_checkout_payment)
#
# # Access Response
#     if do_express_checkout_payment_response.success?
#       response_details = do_express_checkout_payment_response.DoExpressCheckoutPaymentResponseDetails
#       puts "response details: #{response_details}"
#       puts "fmf details: #{do_express_checkout_payment_response.FMFDetails}"
#       # not sure what the object inteface is, so convert into hash data
#       data = JSON.parse(response_details.to_json)
#       puts "hashed response data: #{data}"
#       gross_amount = data['ebl:PaymentInfo'][0]['ebl:GrossAmount']['value']
#       fee_amount = data['ebl:PaymentInfo'][0]['ebl:FeeAmount']['value']
#       render json: {status: 'success', gross_amount: gross_amount, fee_amount: fee_amount}
#     else
#       errors = do_express_checkout_payment_response.Errors
#       puts "errors: #{errors}"
#       render json: {errors: errors}
#     end


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