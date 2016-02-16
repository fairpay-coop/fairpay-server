
# require 'dwolla_swagger'

class DwollaController < ApplicationController

  def initialize
    @dwolla_service = DwollaService.new
  end

  def auth
    redirect_to @dwolla_service.auth_url
  end

  def oauth_complete
    p "params: #{params}"
    code = params[:code]
    p "code: #{code}"
    if code
      token = @dwolla_service.exchange_code_for_token(code)
      # token = @dwolla_service.auth_callback(params)
      render json: {access_token: token.access_token, refresh_token: token.refresh_token, account_id: token.account_id}
    else
      render json: params
    end
  end

end