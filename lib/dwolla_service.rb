# require 'rubygems'
# require 'pp'
# require 'dwolla'
# require 'dwolla_swagger'


class DwollaService


  def self.instance
    @@instance ||= DwollaService.new
  end

  def initialize
    @endpoint = 'https://uat.dwolla.com'
    @access_token = 'GW4JA1uZmgD53hBasnPDrrUDIoNBgWlvC94pNFfHN74Wngt5lo'
    @refresh_token = 'g6jBojtdQmBjceiXAojRG8BV3RnWQAEdMt5LzcMgZbVsBKV4xi'
    @client_id = 'oIAn4ed1iJmfZr6wiOdmEyjsVQmVHBfjOF701xNt7ns4p2IKDF'
    @client_secret = 'dwTh0TPlycLnvXG0S8dHOJjedSkYEGzNum1cE4Qq0Odf6rdGf0'
  #                   PO+SzGAsZCE4BTG7Cw4OAL40Tpf1008mDjGBSVo6QLNfM4mD+a
    @oauth_redirect_url = 'http://local.fairpay.coop:3000/dwolla/oauth_complete'
    @payment_redirect_url = 'http://local.fairpay.coop:3000/dwolla/payment_complete'

  #  https://example.com/return
  #  scope=Balance%7CAccountInfoFull%7CSend%7CRequest%7CTransactions%7CContacts%7CFunding%7CManageAccount%7CScheduled
#    Dwolla::scope = 'send|transactions|balance|request|contacts|accountinfofull|funding'
    # @scope = "Send%7CRequest%7CFunding"
    @scope = "Send|Funding|Balance"

    @code = "DwXCDA2nmzSJFPl7MEGwlMXTYoGs"


    @dwolla = DwollaV2::Client.new(id: @client_id, secret: @client_secret) do |optional_config|
      optional_config.environment = :sandbox
      optional_config.on_grant do |token|
        puts "dwollav2.on_grant - access token: #{token.access_token}, account id: #{token.account_id}"
        # YourTokenData.create! token
        existing = DwollaToken.find_by_account_id(token.account_id)
        if existing
          puts "existing token record id: #{existing.id}"
          existing.update(access_token: token.access_token, refresh_token: token.refresh_token)
          # DwollaToken.create! token
        else
          DwollaToken.create! token
        end
      end
    end

    @auth = DwollaV2::Auth.new(@dwolla, {scope: @scope})

  end

  def api_client
    @dwolla
  end

  def reset_api_config
    # ::Dwolla::api_key = @api_key
    # ::Dwolla::api_secret = @api_secret
    # ::Dwolla::scope = @scope
    #
    #
    DwollaSwagger::Swagger.configure do |config|
      config.access_token = @client_id
      config.host = 'api-uat.dwolla.com'
      config.base_path = '/'
    end
  end

  def auth
    @dwolla.auths.new(redirect_url: @redirect_url, scope: @scope)
  end

  def auth_url
    # reset_api_config
    # url = ::Dwolla::OAuth.get_auth_url(@oauth_redirect_url)
    url = "#{@endpoint}/oauth/v2/authenticate?client_id=#{@client_id}&response_type=code&redirect_uri=#{@redirect_url}&scope=#{@scope}"

    # auth = DwollaV2::Auth.new(c, {scope: @scope})
    auth.url
  end

  def auth_callback(params)
    token = auth.callback(params)
    p "auth_callback - token: #{token}";
    token
  end

  def exchange_code_for_token(code)
    token = auth.callback({code: code})
    #
    # reset_api_config
    # # token = ::Dwolla::OAuth.get_token(code, @oauth_redirect_url)
    # params = {
    #     client_id: @client_id,
    #     client_secret: @client_secret,
    #     code: code,
    #     grant_type: "authorization_code",
    #     redirect_uri: @oauth_redirect_url
    # }
    # DwollaSwagger::RootApi.oauth(params)
    #
    # # "Your never-expiring OAuth access token is: <b>#{token}</b>"
    #
  end

  def refresh(expired_token)
    token = @dwolla.auths.refresh expired_token
    p token
    token
  end

  def token_for_data(data)
    @dwolla.tokens.new data
  end

  def token_for_account_id(account_id)
    data = DwollaToken.find_by(account_id: account_id)
    # token = @dwolla.tokens.new data
    token_for_data(data)
  end

  def token_for_profile_id(profile_id)
    data = DwollaToken.find_by(profile_id: profile_id)
    # token = @dwolla.tokens.new data
    token_for_data(data)
  end

  # handy for console testing
  def last_token
    @dwolla.tokens.new DwollaToken.last
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

  def funding_source_uri_for_id(id)
    "https://api-uat.dwolla.com/funding-sources/#{id}"
  end


  def make_payment(payor_token, payee_token, funding_source_id, amount)
    #todo: only refresh tokens if needed
    payor_token.refresh
    payee_token.refresh

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


  # def make_payment(token, funding_source, destination, amount)
  #   payload = {
  #       _links: {
  #           destination: {href: destination},
  #           source: {href: funding_source}
  #       },
  #       amount: {currency: 'USD', value: amount}
  #   }
  #   token.post '/transfers', payload
  # end


end