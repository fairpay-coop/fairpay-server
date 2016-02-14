class EmbedController < ApplicationController

  def embed
    uuid = params[:uuid]
    embed = Embed.by_uuid(uuid)
    render json: {result: embed}  #todo: api friendly data
  end


  def step1
    embed_uuid = params[:uuid]
    embed = Embed.by_uuid(embed_uuid)

    email = params[:email]
    name = params[:name]
    amount = params[:amount]   # todo: validate decimal conversion

    transaction = embed.step1(email, name, amount)

    result = {transaction_uuid: transaction.uuid}
    render json: {result: result}
  end


  def step2
    embed = Embed.by_uuid(params[:uuid])

    transaction = embed.step2(params)
    result = {status: transaction.status, paid_amount: transaction.paid_amount, estimated_fee: transaction.estimated_fee}
    render json: {result: result}
  end


  def estimate_fee
    bin = params[:bin]
    amount = params[:amount]
    result = Binbase.estimate_fee(bin, amount)
    render json: {result: result}
  end

end
