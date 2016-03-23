class EmbedController < ApplicationController

  ## beware, this has now been superceeded by the Grape app/api/embeds.rb

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

  # beware: not currently used
  def step1
    render_json do
      embed_uuid = params[:uuid]
      embed = Embed.by_uuid(embed_uuid)

      email = params[:email]
      name = params[:name]
      amount = params[:amount]   # todo: validate decimal conversion

      transaction = embed.step1(params)  #email, name, amount)

      result = {transaction_uuid: transaction.uuid}
    end
  end


  def step2
    render_json do
      embed = Embed.by_uuid(params[:uuid])

      transaction = embed.step2(params)
      result = {status: transaction.status,
                paid_amount: transaction.paid_amount,
                estimated_fee: transaction.estimated_fee,
                redirect_url: "/pay/#{params[:uuid]}/thanks/#{params[:transaction_uuid]}"
      }
      puts "step2 - result: #{result}"
      result
    end
  end

  def update_fee_allocation
    puts "update fee allocation - params: #{params.inspect}"
    render_json do
      embed = Embed.by_uuid(params[:uuid])
      result = embed.update_fee_allocation(params)
      puts "update_fee_allocation - result: #{result}"
      result
    end
  end

  def send_dwolla_info
    puts "send_dwolla_info - params: #{params.inspect}"
    render_json do
      embed = Embed.by_uuid(params[:uuid])
      result = embed.send_dwolla_info(params)
      puts "send_dwolla_info - result: #{result}"
      result
    end
  end


  def estimate_fee
    render_json do
      embed = Embed.by_uuid(params[:uuid])
      bin = params[:bin]
      amount = params[:amount]
      embed.card_payment_service.estimate_fee(amount, bin)
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
