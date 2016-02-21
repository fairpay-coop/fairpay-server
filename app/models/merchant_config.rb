class MerchantConfig < ActiveRecord::Base

  # create_table :merchant_configs do |t|
  #   t.references :profile, index: true, foreign_key: true
  #   t.string :kind
  #   t.json :data
  #   t.timestamps null: false

  belongs_to :profile


  KINDS = {stripe: 'Stripe', authorizenet: 'Authorize.Net', dwolla: 'Dwolla', paypal: 'PayPal'}

  def self.kinds
    KINDS
  end


  def payment_service
    case kind
      when 'dwolla'
        DwollaService.instance
      when 'authorizenet'
        AuthorizeNetService.new(self)
      when 'paypal'
        PaypalService.new(data)
      else
        raise "service type: #{kind} - not yet implemented"
    end
  end

end
