class EmbedController < ApplicationController

  def widget_data
    uuid = params[:uuid]
    embed = Embed.by_uuid(uuid)
    result = {
        uuid: embed.uuid,
        payee: embed.profile&.name,
        payment_types: ['card']
    }
    render json: {result: result}
  end


  def step1
    embed_uuid = params[:uuid]
    embed = Embed.by_uuid(embed_uuid)

    email = params[:email]
    name = params[:name]
    amount = params[:amount]   # todo: validate decimal conversion

    transaction = embed.step1(email, name, amount)

    result = {transaction_uuid: transaction.uuid}
    puts "step1 - result: #{result}"
    callback = params[:callback]
    render_response(result, callback)
  end


  def step2
    embed = Embed.by_uuid(params[:uuid])

    transaction = embed.step2(params)
    result = {status: transaction.status, paid_amount: transaction.paid_amount, estimated_fee: transaction.estimated_fee}
    puts "step2 - result: #{result}"
    # render json: {result: result}
    callback = params[:callback]
    render_response(result, callback)
  end

  def render_response(result, callback=nil)
    response = {result: result}
    if callback
      render text: "#{callback}(#{response.to_json});"
    else
      render json: response
    end
  end

  def estimate_fee
    bin = params[:bin]
    amount = params[:amount]
    result = Binbase.estimate_fee(bin, amount)
    render json: {result: result}
  end

end
