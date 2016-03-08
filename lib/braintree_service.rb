
class BraintreeService < ActiveMerchantService

  # example merchant config:
  #   {merchant_id: 'X', public_key: 'Y', private_key: 'Z', mode: 'test'}

  FEE_CONFIG = {base: 0.30, percent: 2.9}


  def initialize_gateway(merchant_config)
    gateway_params = merchant_config.indifferent_data.slice(:merchant_id, :public_key, :private_key)
    @gateway = ActiveMerchant::Billing::BraintreeGateway.new(gateway_params)
    # puts "braintree gateway: #{@gateway.inspect}"
  end


  def payment_type
    :braintree
  end

  def payment_type_display
    'Card (Braintree)'
  end



end