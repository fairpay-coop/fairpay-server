class WidgetController < ApplicationController
  before_filter :allow_iframe_requests, except: :widget_js
  skip_before_action :verify_authenticity_token, only: [:widget_js, :ping]

  def widget_js
    @iframe_src =  url_for :controller => 'widget', :action => 'capture_id', uuid: params[:uuid], amount: params[:amount]
    #beware: these dimensions don't seem to be honored
    @width = 500
    @height = 500
    respond_to do |format|
      format.js { render }
    end
  end

  def capture_id
    @embed = Embed.by_uuid(params[:uuid])
    @amount = params[:amount]
  end

  def update_id
    embed_uuid = params[:uuid]
    embed = Embed.by_uuid(embed_uuid)

    amount = params[:amount]
    email = params[:email]
    name = params[:name]

    transaction = embed.step1(params) #email, name, amount)

    # session[:step2_uri] = "/widget/#{embed.uuid}/authComplete/#{transaction.uuid}"
    session[:current_url] = "/widget/#{embed.uuid}/authComplete/#{transaction.uuid}"

    redirect_to "/widget/#{embed.uuid}/capturePayment/#{transaction.uuid}"
  end

  def capture_payment
    @embed = Embed.by_uuid(params[:uuid])
    @transaction = Transaction.by_uuid(params[:transaction_uuid])
    @default_payment_type = params[:payment_type] || :card
  end

  def update_payment
    embed = Embed.by_uuid(params[:uuid])
    transaction = embed.step2(params)
    redirect_to "/widget/#{embed.uuid}/paymentComplete/#{transaction.uuid}"
  end

  def payment_complete
    @embed = Embed.by_uuid(params[:uuid])
    @transaction = Transaction.by_uuid(params[:transaction_uuid])
  end

  def auth_complete

  end

  def ping
    render plain: params.to_json
  end


  def iframe
    render layout: false
  end


  private
  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end

end
