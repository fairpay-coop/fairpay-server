class PayController < ApplicationController
  include ApplicationHelper


  def widget
    uuid = params[:uuid]
    @embed = Embed.resolve(uuid)
    # render layout: false
  end

  def iframe
    uuid = params[:uuid]
    @embed = Embed.resolve(uuid)
  end


  def step1
    embed_uuid = params[:uuid]
    puts "current user: #{current_user}"

    embed_params = params.permit(:amount, :description, :return_url, :correlation_id, :offer) #, :uuid)
    embed_params[:session_data] = session_data

    embed = Embed.resolve(embed_uuid)
    @data = hashify( embed.embed_data(embed_params) )
    puts "embed data: #{@data}"

    if params[:json]
      render json: @data
    else
      @data
    end

  end


  def step2
    embed = Embed.by_uuid(params[:uuid])
    transaction = Transaction.by_uuid(params[:transaction_uuid])

    raise "invalid transaction id: #{params[:transaction_uuid]}" unless transaction #todo confirm provisional status
    # raise "missing transaction amount"  unless @transaction.base_amount && @transaction.base_amount > 0
    #
    # @dwolla_authenticated = session[:dwolla_authenticated]  # make sure to allow just authenticated session
    # if current_user && current_user.email == @transaction.payor.email
    #   puts "authenticated user session - stored payments available"
    #   @profile_authenticated = true   # rename this to something dwolla specific
    # end
    # used to resume after login
    session[:current_url] = transaction.step2_url

    @data = hashify( transaction.step2_data(session_data) )

    if params[:json]
      render json: @data
    else
      @data
    end

  end

  def address
    embed = Embed.by_uuid(params[:uuid])
    transaction = Transaction.by_uuid(params[:transaction_uuid])

    raise "invalid transaction id: #{params[:transaction_uuid]}" unless transaction #todo confirm provisional status

    session[:current_url] = transaction.step2_url

    @data = hashify( transaction.step2_data(session_data) )

    if params[:json]
      render json: @data
    else
      @data
    end

  end


  def step2_post
    embed = Embed.by_uuid(params[:uuid])
    transaction = embed.step2(params)
    redirect_to "/pay/#{embed.uuid}/thanks/#{transaction.uuid}"
  end


  def thanks
    @embed = Embed.by_uuid(params[:uuid])
    @transaction = Transaction.by_uuid(params[:transaction_uuid])
    # used to redisplay after signup
    session[:current_url] = @transaction.finished_url

    embed = Embed.by_uuid(params[:uuid])
    transaction = Transaction.by_uuid(params[:transaction_uuid])

    @data = hashify( transaction.step2_data(session_data) )  #todo: consider different view of data

    if params[:json]
      render json: @data
    else
      @data
    end
  end

  def merchant_receipt
    @embed = Embed.by_uuid(params[:uuid])
    @transaction = Transaction.by_uuid(params[:transaction_uuid])
  end


  private

  def session_data
    {
      email: session[:email],
      authenticated_user: current_user
    }
  end



  # note, this won't work in a single proc dev environment
  # private
  # def fetch_widget_data(embed_uuid, params)
  #   url = "#{base_url}/api/v1/embeds/#{embed_uuid}/widget_data"
  #   response = RestClient.get url, params: params
  #   puts "response: #{response}"
  #   JSON.parse(response)
  # end



end
