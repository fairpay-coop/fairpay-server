class DwollaService
  include Singleton


  # def self.instance
  #   @@instance ||= DwollaService.new
  # end

  SCOPE = "Send|Request|Funding|Balance"

  def initialize
    dwolla_environment = ENV['DWOLLA_ENVIRONMENT']
    @environment = dwolla_environment.to_sym  if dwolla_environment
    client_id = ENV['DWOLLA_CLIENT_ID']
    client_secret = ENV['DWOLLA_CLIENT_SECRET']

    puts "dwolla env: #{dwolla_environment}, client id: #{client_id}"

    # @oauth_redirect_url = 'http://local.fairpay.coop:3000/dwolla/oauth_complete'
    # @payment_redirect_url = 'http://local.fairpay.coop:3000/dwolla/payment_complete'

    @dwolla = DwollaV2::Client.new(id: client_id, secret: client_secret) do |optional_config|
      optional_config.environment = @environment  if @environment
      optional_config.on_grant do |token|
        puts "dwollav2.on_grant - access token: #{token.access_token}, account id: #{token.account_id}"
        existing = DwollaToken.find_by_account_id(token.account_id)
        if existing
          puts "existing token record id: #{existing.id}"
          existing.update(access_token: token.access_token, refresh_token: token.refresh_token)
        else
          DwollaToken.create! token
        end
      end
    end

  end

  def api_client
    @dwolla
  end

  def auth
    # @dwolla.auths.new(redirect_url: @redirect_url, scope: SCOPE)
    @dwolla.auths.new(redirect_url: '', scope: SCOPE)
  end

  def auth_url
    auth.url + "&dwolla_landing=login"  #todo: figure clean api method
  end

  def exchange_code_for_token(code)
    token = auth.callback({code: code})
  end

  def refresh(expired_token)
    token = @dwolla.auths.refresh expired_token
    puts "refreshed token: #{token}"
    token
  end

  def token_for_data(data)
    @dwolla.tokens.new data
  end

  def token_for_account_id(account_id)
    data = DwollaToken.find_by(account_id: account_id)
    token_for_data(data)
  end

  def token_for_profile_id(profile_id)
    data = DwollaToken.find_by(profile_id: profile_id)
    token_for_data(data)
  end

  def list_funding_sources(token)
    raw = token.get "/accounts/#{token.account_id}/funding-sources"
    puts "raw: #{raw.to_json}"
    result = {}
    raw[:_embedded][:'funding-sources'].each do |data|
      puts "data: #{data}"
      name = data[:name]
      id = data[:id]
      href = data[:_links][:self][:href]
      if name == 'Balance'
        details = token.get "funding-sources/#{id}"
        puts "balance details: #{details.to_json}"
        balance_obj = details[:balance]
        name = "Dwolla Balance: #{balance_obj[:value]} #{balance_obj[:currency]}"  if balance_obj
      end

      result[id] = name
    end
    result
  end


  # the need for this could be avoided with some reworking
  def funding_source_uri_for_id(id)
    "#{api_base_url}/funding-sources/#{id}"
  end

  # the need for this could be avoided with some reworking
  def api_base_url
    if @environment == :sandbox
      "https://api-uat.dwolla.com"
    else
      "https://api.dwolla.com"
    end
  end


  def handle_payment(transaction, params)
    funding_source_id = params[:funding_source_id]

    estimated_fee = 0.00
    paid_amount = transaction.base_amount + estimated_fee

    make_payment(transaction.payor.dwolla_token, transaction.payee.dwolla_token, funding_source_id, paid_amount)

    [paid_amount, estimated_fee]
  end


  def make_payment(payor_token, payee_token, funding_source_id, amount)

    raise "funding source required"  unless funding_source_id

    #note payor  and payee tokens are automatically refreshed as needed
    destination = payee_token.account_uri
    funding_source = funding_source_uri_for_id(funding_source_id)

    payload = {
        _links: {
            destination: {href: destination},
            source: {href: funding_source}
        },
        amount: {currency: 'USD', value: amount}
    }
    payor_token.token.post '/transfers', payload
  end


  def calculate_fee(amount, params)
    0.0
  end


  # which form partial to render for this payment type
  # def form_partial
  #   'dwolla'
  # end


  ##
  ## code snippets from other sdk layers
  ##

  # require 'rubygems'
  # require 'pp'
  # require 'dwolla'
  # require 'dwolla_swagger'

  # def reset_api_config
  #   # ::Dwolla::api_key = @api_key
  #   # ::Dwolla::api_secret = @api_secret
  #   # ::Dwolla::scope = @scope
  #   #
  #   #
  #   DwollaSwagger::Swagger.configure do |config|
  #     config.access_token = @client_id
  #     config.host = 'api-uat.dwolla.com'
  #     config.base_path = '/'
  #   end
  # end


  # def exchange_code_for_token(code)
  #   reset_api_config
  #   # token = ::Dwolla::OAuth.get_token(code, @oauth_redirect_url)
  #   params = {
  #       client_id: @client_id,
  #       client_secret: @client_secret,
  #       code: code,
  #       grant_type: "authorization_code",
  #       redirect_uri: @oauth_redirect_url
  #   }
  #   DwollaSwagger::RootApi.oauth(params)
  # end

  # def auth_url
  #   reset_api_config
  #   # url = ::Dwolla::OAuth.get_auth_url(@oauth_redirect_url)
  #   url = "#{@endpoint}/oauth/v2/authenticate?client_id=#{@client_id}&response_type=code&redirect_uri=#{@redirect_url}&scope=#{SCOPE}"
  # end
  # @auth = DwollaV2::Auth.new(@dwolla, {scope: SCOPE})


end