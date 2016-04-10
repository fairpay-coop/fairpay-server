
class DwollaController < ApplicationController

  # def initialize
  #   @dwolla_service = DwollaService.instance
  # end

  def dwolla_service(transaction)
    transaction.embed.dwolla_service
  end

  def auth
    transaction_uuid = params[:t]
    origin = params[:o] || 'hosted'
    puts "t uuid: #{transaction_uuid} - origin: #{origin}"
    # session[:transaction_uuid] = params[:t]
    # session[:origin] = params[:o]

    transaction = Transaction.find_by(uuid: transaction_uuid)
    raise "transaction not found for uuid: #{transaction_uuid}"  unless transaction
    service = dwolla_service(transaction)

    redirect_to service.auth_url(transaction_uuid, origin)
  end

  def oauth_complete
    p "oauth_complete - params: #{params}"
    code = params[:code]
    p "code: #{code}"
    if code
      transaction_uuid = params[:t]
      origin = params[:o]
      raise "transaction_uuid not found in session"  unless transaction_uuid
      puts "t uuid: #{transaction_uuid}"
      transaction = Transaction.find_by(uuid: transaction_uuid)
      raise "transaction not found for uuid: #{transaction_uuid}"  unless transaction

      service = dwolla_service(transaction)

      token = service.exchange_code_for_token(code, transaction_uuid, origin)
      # dwolla_token = DwollaToken.find_by(app_id: service.client_id, access_token: token.access_token)
      dwolla_token = service.dwolla_token_for_access_token(token.access_token)
      raise "DwollaToken not found for access_token: #{token.access_token}"  unless dwolla_token

      service.associate_dwolla_account_id(transaction.payor, dwolla_token.account_id)

      # transaction_uuid = params[:t]
      # step2_uri = session[:step2_uri]
      # session[:dwolla_authenticated] = true
      transaction.update!(dwolla_authenticated: true)

      if origin == 'widget'
        render action: :autoclose, layout: false
      else
        step2_uri = session[:current_url]
        if step2_uri
          redirect_to step2_uri
        else
          render json: {access_token: token.access_token, refresh_token: token.refresh_token, account_id: token.account_id}
        end
      end

    else
      render json: params
    end
  end

  def autoclose
  end

  # def make_payment
  #   transaction_uuid = params[:t]
  #   puts "t uuid: #{transaction_uuid}"
  #   transaction = Transaction.find_by(uuid: transaction_uuid)
  #   raise "transaction not found for uuid: #{transaction_uuid}"  unless transaction
  #   # transaction.payor.dwolla_token.make_payment(transaction.payee.dwolla_token, transaction.amount)
  #   transaction.pay_via_dwolla
  #   render json: 'success'
  # end

end