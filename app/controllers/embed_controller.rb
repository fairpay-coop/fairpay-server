class EmbedController < ApplicationController

  def widget_data
    render_json do
      uuid = params[:uuid]
      embed = Embed.by_uuid(uuid)
      result = {
          uuid: embed.uuid,
          payee: embed.profile&.name,
          payment_types: ['card']
      }
    end

  end


  def step1
    render_json do
      embed_uuid = params[:uuid]
      embed = Embed.by_uuid(embed_uuid)

      email = params[:email]
      name = params[:name]
      amount = params[:amount]   # todo: validate decimal conversion

      transaction = embed.step1(email, name, amount)

      result = {transaction_uuid: transaction.uuid}
    end
  end


  def step2
    render_json do
      embed = Embed.by_uuid(params[:uuid])

      transaction = embed.step2(params)
      result = {status: transaction.status, paid_amount: transaction.paid_amount, estimated_fee: transaction.estimated_fee}
      puts "step2 - result: #{result}"
      result
    end
  end


  def estimate_fee
    render_json do
      bin = params[:bin]
      amount = params[:amount]
      result = Binbase.estimate_fee(bin, amount)
    end
  end

  def render_json
    begin
      result = yield
      response = {result: result}
    rescue Exception => e
      p "api error, e: #{e.inspect}\n#{e.backtrace.inspect}"
      # response = {error: {code: 100, message: e.inspect}}
      response = {error: {code: 100, message: e.message}}
    end
    callback = params[:callback]
    p "callback: #{callback}, resp: #{response.to_json}"
    if callback
      render text: "#{callback}(#{response.to_json});"
    else
      render json: response
    end
  end


end
