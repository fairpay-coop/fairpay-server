class PayController < ApplicationController

  def embed
    uuid = params[:uuid]
    @embed = Embed.by_uuid(uuid)
  end

  def iframe
    uuid = params[:uuid]
    @embed = Embed.by_uuid(uuid)
  end


  def step1
    embed_uuid = params[:uuid]
    @embed = Embed.by_uuid(embed_uuid)

  end

  def step1_post
    embed_uuid = params[:uuid]
    embed = Embed.by_uuid(embed_uuid)

    # amount = params[:amount]   # todo: validate decimal conversion
    # email = params[:email]
    # name = params[:name]
    # recurrence = params[:recurrence]
    data = params.slice(:name, :email, :amount, :recurrence, :mailing_list)

    transaction = embed.step1(data) #email, name, amount, recurrence)

    step2_uri = "/pay/#{embed.uuid}/step2/#{transaction.uuid}" #"?payment_type=#{payment_type}"
    session[:step2_uri] = step2_uri

    redirect_to step2_uri #"/pay/#{embed.uuid}/step2/#{transaction.uuid}?payment_type=#{payment_type}" #, {payment_type: payment_type}
  end


  def step2
    @embed = Embed.by_uuid(params[:uuid])
    @transaction = Transaction.by_uuid(params[:transaction_uuid])
  end

  def step2_post
    embed = Embed.by_uuid(params[:uuid])
    transaction = embed.step2(params)
    redirect_to "/pay/#{embed.uuid}/thanks/#{transaction.uuid}"
  end

  # def step2_dwolla_post
  #   embed = Embed.by_uuid(params[:uuid])
  #   transaction = embed.step2(params)
  #   redirect_to "/pay/#{embed.uuid}/thanks/#{transaction.uuid}"
  # end


  def pay_via_dwolla
    # transaction_uuid = params[:transaction_uuid]
    # p "t uuid: #{transaction_uuid}"
    # transaction = Transaction.find_by(uuid: transaction_uuid)
    # raise "transaction not found for uuid: #{transaction_uuid}"  unless transaction
    # # transaction.payor.dwolla_token.make_payment(transaction.payee.dwolla_token, transaction.amount)
    # transaction.pay_via_dwolla

    embed = Embed.by_uuid(params[:uuid])
    transaction = embed.pay_via_dwolla(params)

    redirect_to "/pay/#{embed.uuid}/thanks/#{transaction.uuid}"
  end


  def thanks
    @embed = Embed.by_uuid(params[:uuid])
    @transaction = Transaction.by_uuid(params[:transaction_uuid])

  end


  def estimate_fee
    bin = params[:bin]
    amount = params[:amount]
    result = Binbase.estimate_fee(bin, amount)
    render json: result
  end


  def paypal
  end

end
