class DwollaService  < BasePaymentService
  include ApplicationHelper
  # not sure if we should still use a singleton here or not
  # include Singleton

  SCOPE = "Send|Request|Funding|Balance"

  FEE_CONFIG = {base: 0, percent: 0}

  DEFAULT_CONFIG = {
      mode: ENV['DWOLLA_ENVIRONMENT'],
      client_id: ENV['DWOLLA_CLIENT_ID'],
      client_secret: ENV['DWOLLA_CLIENT_SECRET'],
  }

  # merchant config params:
  #  mode: 'default' (production), 'sandbox'
  #  client_id
  #  client_secret
  #
  # beware, if customized dwolla config is used for a particular embed,
  # then (for now) payor profiles must be kept distinct between dwolla realms
  # todo:


  def initialize(merchant_config)
    config = merchant_config&.indifferent_data
    unless config && config[:client_id]
      config = DEFAULT_CONFIG
      puts "using default dwolla config: #{config.inspect}"
    end

    @environment = (config[:mode] || config[:environment] || :default).to_sym  #todo: consolidate config on 'mode' vs 'environment'
    @environment = :default  if @environment == :live  # support 'live' as a standardized alias for 'default'

    @client_id = config[:client_id]
    client_secret = config[:client_secret]
    client_id = client_id

    puts "dwolla env: #{@environment}, client id: #{@client_id}"

    @oauth_redirect_url = "#{base_url}/dwolla/oauth_complete"

    @dwolla = DwollaV2::Client.new(id: @client_id, secret: client_secret) do |optional_config|
      optional_config.environment = @environment  if @environment
      optional_config.on_grant do |token|
        puts "dwollav2.on_grant - access token: #{token.access_token}, account id: #{token.account_id}"
        puts "token inspect: #{token.inspect}"
        # existing = DwollaToken.find_by_account_id(token.account_id, @client_id)
        existing = dwolla_token_for_account_id(token.account_id)
        if existing
          puts "existing token record id: #{existing.id}"
          existing.update(access_token: token.access_token, refresh_token: token.refresh_token)
        else
          token_data = token.stringify_keys
          token_data["client_id"] = @client_id
          DwollaToken.create! token_data
        end
      end
    end

    # clean this up once initializer api fixed
    # initialize_fee_service(nil)
    @fee_service = FeeService.new(FEE_CONFIG, self)
  end

  def default_fee_config
    FEE_CONFIG
  end


  # def fee_service
  #   @fee_service
  # end


  def api_client
    @dwolla
  end

  def client_id
    @client_id
  end

  def auth
    # @dwolla.auths.new(redirect_url: @redirect_url, scope: SCOPE)
    puts "redirect url: #{@oauth_redirect_url}"
    @dwolla.auths.new(redirect_uri: @oauth_redirect_url, scope: SCOPE)
  end

  def auth_url

    # puts "dwolla environment: #{ENV['DWOLLA_ENVIRONMENT']}"
    # puts "dwolla client id: #{ENV['DWOLLA_CLIENT_ID']}"

    auth.url + "&dwolla_landing=login"  #todo: figure clean api method
  end

  def exchange_code_for_token(code)
    token = auth.callback({code: code})
  end

  def refresh_raw_token(expired_token)
    token = @dwolla.auths.refresh expired_token
    puts "refreshed token: #{token}"
    token
  end

  def refresh_dwolla_token(dwolla_token)
    raw_token = token_for_data(dwolla_token)
    refreshed = refresh_raw_token(raw_token)
    self.update!(access_token: refreshed.access_token)
    # need to make sure both local and persisted instances are updated
    self.access_token = refreshed.access_token
    self.updated_at = Time.now
    # self.save!
  end

  # def raw_token(dwolla_token)
  #   token_for_data(dwolla_token)
  # end




  def token_for_data(data)
    @dwolla.tokens.new data
  end

  def dwolla_token_for_account_id(account_id)
    DwollaToken.find_by(account_id: account_id, client_id: client_id)
  end

  def token_for_account_id(account_id)
    data = dwolla_token_for_account_id(account_id)
    token_for_data(data)
  end

  def dwolla_token_for_access_token(access_token)
    DwollaToken.find_by(client_id: client_id, access_token: access_token)
  end



  # def token_for_profile_id(profile_id)
  #   data = DwollaToken.find_by(profile_id: profile_id)
  #   token_for_data(data)
  # end

  def payment_source_for_transaction(transaction)
    transaction.payor.dwolla_payment_source(client_id)
  end

  def has_dwolla_auth(transaction)
    payment_source = payment_source_for_transaction(transaction)
    payment_source&.get_data_field(:account_id).present?
  end

  def funding_sources(transaction)
    # token = transaction.payor.dwolla_token
    dwolla_token = dwolla_token_for_profile(transaction.payor)
    list_funding_sources(dwolla_token, transaction.base_amount)
  end


  def dwolla_token_for_profile(profile)
    payment_source = profile.dwolla_payment_source(client_id)
    if payment_source
      account_id = payment_source.get_data_field(:account_id)
      dwolla_token_for_account_id(account_id)
    end
  end



  def list_funding_sources(dwolla_token, amount = 0.0)
    token = dwolla_token.token(self)
    raw = token.get "/accounts/#{token.account_id}/funding-sources"
    puts "raw: #{raw.to_json}"
    result = []
    default_id = nil
    raw[:_embedded][:'funding-sources'].each do |data|
      puts "data: #{data}"
      selected = false
      name = data[:name]
      id = data[:id]
      href = data[:_links][:self][:href]
      if name == 'Balance'
        details = token.get "funding-sources/#{id}"
        puts "balance details: #{details.to_json}"
        balance_obj = details[:balance]
        if balance_obj
          # for now assume USD
          balance = balance_obj[:value].to_f
          name = "Dwolla Balance: #{balance_obj[:value]} #{balance_obj[:currency]}"
          if amount <= balance
            default_id = id
            # selected = true
            result.insert(0, {id: id, name: name, selected: true})
          else
            puts "balance unavailable - source skipped - token: #{token}"
            #todo: display balance as a disabled option instead of silently skipping
          end
        end
      else
        result << {id: id, name: name}
      end
    end
    unless default_id
      first = result.first
      if first
        first[:selected] = true
      else
        puts "warning, no available funding sources found for dwolla token: #{token}"
      end
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


  def associate_dwolla_account_id(profile, account_id)
    payment_source = profile.dwolla_payment_source(client_id, autocreate: true)
    payment_source.update_data_field(:account_id, account_id)
  end


  # def dwolla_token_make_payment(payor_dwolla_token, payee_dwolla_token, amount)
  #   # access tokens expire after 1 hour.  for now assume always needs refreshing before any transaction
  #   # self.refresh
  #   puts "access token before refresh: #{payee_dwolla_token.access_token}"
  #   # payee_dwolla_token.refresh
  #   puts "access token after refresh: #{payee_dwolla_token.access_token}"
  #   make_payment(payor_dwolla_token.token, self.default_funding_source_uri, payee_dwolla_token.account_uri, amount)
  # end


  def handle_payment(transaction, params)
    funding_source_id = params[:funding_source_id]

    estimated_fee = 0.00
    paid_amount = transaction.base_amount + estimated_fee

    payor_token = dwolla_token_for_profile(transaction.payor)
    payee_token = dwolla_token_for_profile(transaction.payee)
    raise "missing payee_token - profile id: #{transaction.payee.id}"  unless payee_token
    make_payment(payor_token, payee_token, funding_source_id, paid_amount)

    [paid_amount, estimated_fee]
  end


  def make_payment(payor_token, payee_token, funding_source_id, amount)

    raise "funding source required"  unless funding_source_id

    #note payor  and payee tokens are automatically refreshed as needed
    destination = payee_token.account_uri(self)
    funding_source = funding_source_uri_for_id(funding_source_id)

    payload = {
        _links: {
            destination: {href: destination},
            source: {href: funding_source}
        },
        amount: {currency: 'USD', value: amount}
    }
    payor_token.token(self).post '/transfers', payload
  end

  # def account_uri_for_dwolla_token(dwolla_token)
  #   data = token.get("accounts/#{account_id}")
  #   data[:_links][:self][:href]
  # end

  # def token_for_dwolla_token(dwolla_token)
  #   refresh  if dwolla_token.stale_token?
  #   raw_token
  # end


  # def calculate_fee(amount, params)
  #   0.0
  # end


  def payment_type_display
    'Dwolla'
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