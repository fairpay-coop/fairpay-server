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
    embed_params[:session_data] = resolve_session_data

    embed = Embed.resolve(embed_uuid)
    @data = hashify( embed.embed_data(embed_params) )
    # @data[:auth_token] = session_auth_token
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

    # resolved_session_data = resolve_session_data(params)

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

    @data = hashify( transaction.step2_data )

    if params[:json]
      render json: @data
    else
      @data
    end

  end

  def address
    embed = Embed.by_uuid(params[:uuid])
    transaction = Transaction.by_uuid(params[:transaction_uuid])
    # resolved_session_data = resolve_session_data(params)

    raise "invalid transaction id: #{params[:transaction_uuid]}" unless transaction #todo confirm provisional status

    session[:current_url] = transaction.step2_url

    @data = hashify( transaction.step2_data )

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
    # resolved_session_data = resolve_session_data(params)
    # used to redisplay after signup
    session[:current_url] = @transaction.finished_url

    embed = Embed.by_uuid(params[:uuid])
    transaction = Transaction.by_uuid(params[:transaction_uuid])

    @data = hashify( transaction.step2_data )  #todo: consider different view of data

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

  # # honor passed param in if present, otherwise look to rails session and pass back auth_token for current user
  # def resolve_session_data(params)
  #   if params[:auth_token].present?
  #     auth_token = params[:auth_token]
  #     puts "resolve - auth_token from params: #{auth_token}"
  #   else
  #     auth_token = current_user&.ensure_persisted_auth_token
  #     puts "resolve - auth_token from session: #{auth_token}"
  #   end
  #   {
  #     # email: session[:email],
  #     # authenticated_user: current_user
  #     auth_token: auth_token
  #   }
  # end


  # return the simple hosted flow equivalent to what would be stored in the widget js cookie data
  def resolve_session_data
    auth_token = current_user&.ensure_persisted_auth_token
    puts "resolve - auth_token from session: #{auth_token}"
    {
      # email: session[:email],
      # authenticated_user: current_user
      auth_token: auth_token
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
