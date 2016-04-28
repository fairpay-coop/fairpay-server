class AbuntooController < PayController
  include ApplicationHelper

  layout 'abuntoo'

  def index
    embed = resolve_embed(params)
    return no_context  unless embed

    embed_params = {} # not relevant for now
    @data = hashify( embed.embed_data(embed_params) )
  end

  def no_context
    render 'welcome/no_context', layout: 'application'
  end

  def donate
    embed = resolve_embed(params)
    return no_context  unless embed

    # embed_uuid = resolve_embed_uuid #params[:uuid]
    puts "current user: #{current_user}"

    embed_params = params.permit(:amount, :description, :return_url, :correlation_id, :offer) #, :uuid)
    embed_params[:session_data] = resolve_session_data

    # embed = Embed.resolve(embed_uuid)
    @data = hashify( embed.embed_data(embed_params) )
    # @data[:auth_token] = session_auth_token
    puts "embed data: #{@data}"

    if params[:json]
      render json: @data
    else
      @data
    end
    render 'donate_raw'  if params[:raw]
  end

  def payment
    embed = resolve_embed(params)
    return no_context  unless embed

    # embed = Embed.by_uuid(params[:uuid])
    transaction = Transaction.by_uuid(params[:transaction_uuid])
    raise "invalid transaction id: #{params[:transaction_uuid]}" unless transaction #todo confirm provisional status
    session[:current_url] = transaction.step2_url

    # patch the current transaction with the authenticator
    unless transaction.payor
      puts "payment - payor missing - cookies: #{cookies.to_json}"
      authenticated_profile = auth0_profile
      if authenticated_profile
        #todo: should probably move this into a transaction instance method
        puts "updating transaction payor with authenticated profile: #{authenticated_profile.inspect}"
        transaction.update!(payor: authenticated_profile, profile_authenticated: true)
      end
    end

    @data = hashify( transaction.step2_data )

    if params[:json]
      render json: @data
    else
      @data
    end
    render 'payment_raw'  if params[:raw]
  end

  def thanks
    embed = resolve_embed(params)
    return no_context  unless embed

    # @embed = Embed.by_uuid(params[:uuid])
    @transaction = Transaction.by_uuid(params[:transaction_uuid])
    # resolved_session_data = resolve_session_data(params)
    # used to redisplay after signup
    session[:current_url] = @transaction.finished_url

    # embed = Embed.by_uuid(params[:uuid])
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
    @data = hashify( @transaction.step2_data )  #todo: consider different view of data
    render 'pay/merchant_receipt'
  end

  def terms
  end

  def privacy
  end

  protected

  def resolve_embed(params)
    result = TenantState.current_embed
    unless result
      uuid = params[:uuid] || ENV['STANDALONE_EMBED_UUID']
      result = Embed.resolve(uuid, required: false)
    end
    result
  end

end
