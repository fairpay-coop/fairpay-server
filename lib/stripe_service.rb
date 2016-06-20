
class StripeService < ActiveMerchantService

  # example merchant config:
  #   {login: 'sk_test_xxxx'}

  FEE_CONFIG = {base: 0.30, percent: 2.9}


  def initialize_gateway(merchant_config)
    gateway_params = merchant_config.indifferent_data.slice(:login)
    @gateway = ActiveMerchant::Billing::StripeGateway.new(gateway_params)
    puts "stripe gateway: #{@gateway.inspect}"
  end


  def payment_type
    :stripe
  end

  def payment_type_display
    'Card (Stripe)'
  end



end