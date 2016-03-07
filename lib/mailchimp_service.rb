# note, not a payment service, but using the merchant config to consolidate handling of sensitive api credentials

class MailchimpService

  # example merchant config:
  #   {api_key: 'X', list_id: 'Y', double_optin: true}

  def initialize(merchant_config)
    @gibbon = Gibbon::Request.new(api_key: merchant_config.get_data_field(:api_key))
    @list_id = merchant_config.get_data_field(:list_id)
    @double_optin = merchant_config.get_data_field(:double_optin).to_s == 'true'  # handle boolean or string assignment
    puts "mailchimp init - list: #{@list_id}, optin: #{@double_optin}"
  end

  def subscribe(profile, list_id: nil, double_optin: nil)
    list_id ||= @list_id
    double_optin ||= @double_optin
    puts "subscribe - email: #{profile.email}, list: #{list_id}, optin: #{double_optin}"
    status = double_optin ? "pending" : "subscribed"
    body = { email_address: profile.email, status: status, merge_fields: {FNAME: profile.first_name, LNAME: profile.last_name} }
    @gibbon.lists(list_id).members.create(body: body)
  end


end