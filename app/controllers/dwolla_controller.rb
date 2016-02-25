
# require 'dwolla_swagger'

class DwollaController < ApplicationController

  def initialize
    @dwolla_service = DwollaService.instance
  end

  def auth
    transaction_uuid = params[:t]
    puts "t uuid: #{transaction_uuid}"
    session[:transaction_uuid] = params[:t]
    redirect_to @dwolla_service.auth_url
  end

  def oauth_complete
    p "oauth_complete - params: #{params}"
    code = params[:code]
    p "code: #{code}"
    if code
      token = @dwolla_service.exchange_code_for_token(code)
      # token = @dwolla_service.auth_callback(params)
      # dwolla_token = DwollaToken.find_by(account_id: token.account_id)
      dwolla_token = DwollaToken.find_by(access_token: token.access_token)
      raise "DwollaToken not found for access_token: #{token.access_token}"  unless dwolla_token
      transaction_uuid = session[:transaction_uuid]
      raise "transaction_uuid not found in session"  unless transaction_uuid
      puts "t uuid: #{transaction_uuid}"
      transaction = Transaction.find_by(uuid: transaction_uuid)
      raise "transaction not found for uuid: #{transaction_uuid}"  unless transaction

      # dwolla_token.update({profile: transaction.payor})
      transaction.payor.associate_dwolla_account_id(dwolla_token.account_id)

      transaction_uuid = params[:t]
      step2_uri = session[:step2_uri]
      if step2_uri
        redirect_to step2_uri
      else
        render json: {access_token: token.access_token, refresh_token: token.refresh_token, account_id: token.account_id}
      end

    else
      render json: params
    end
  end

  def make_payment
    transaction_uuid = params[:t]
    puts "t uuid: #{transaction_uuid}"
    transaction = Transaction.find_by(uuid: transaction_uuid)
    raise "transaction not found for uuid: #{transaction_uuid}"  unless transaction
    # transaction.payor.dwolla_token.make_payment(transaction.payee.dwolla_token, transaction.amount)
    transaction.pay_via_dwolla
    render json: 'success'
  end

end