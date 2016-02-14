class PayController < ApplicationController
  def embed
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

    amount = params[:amount]   # todo: validate decimal conversion
    email = params[:email]
    name = params[:name]

    transaction = embed.step1(email, name, amount)

    redirect_to "/pay/#{embed.uuid}/step2/#{transaction.uuid}"
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

end
