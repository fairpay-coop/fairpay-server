# PayPal::SDK.load("config/paypal.yml", Rails.env)
# PayPal::SDK.logger = Rails.logger

# require 'paypal-sdk-merchant'

PayPal::SDK.configure(
    mode:   ENV['PAYPAL_MODE'],
    # app_id doesn't seem to be required, and i can't find value in my paypal admin panel
    # app_id: ENV['PAYPAL_APP_ID'],
    username: ENV['PAYPAL_API_USERNAME'],
    password: ENV['PAYPAL_API_PASSWORD'],
    signature: ENV['PAYPAL_API_SIGNATURE'],
    http_timeout: 30
)


# @api = PayPal::SDK::Merchant.new
