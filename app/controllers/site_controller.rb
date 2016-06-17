class SiteController < ApplicationController
  include ApplicationHelper

  # layout 'site/default/application'

  def index
    embed = resolve_embed(params)
    return no_context  unless embed

    embed_params = {} # not relevant for now
    @data = hashify( embed.embed_data(embed_params) )
    themed_render(embed, params)
  end

  # def index2
  #   embed = resolve_embed(params)
  #   return no_context  unless embed
  #
  #   embed_params = {} # not relevant for now
  #   @data = hashify( embed.embed_data(embed_params) )
  #   # themed_render(embed, params)
  #
  #   render 'abuntoo/site/index2', layout: nil
  #
  # end


  def no_context
    render 'welcome/no_context', layout: 'application'
  end

  #todo: need more generic action name
  def donate
    #todo: factor this pattern to a 'before_method' list
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

    #todo: factor out this pattern
    if params[:json]
      render json: @data
    else
      themed_render(embed, params)
    end
  end

  def address
    embed = resolve_embed(params)
    return no_context  unless embed

    transaction = Transaction.by_uuid(params[:transaction_uuid])
    # resolved_session_data = resolve_session_data(params)

    raise "invalid transaction id: #{params[:transaction_uuid]}" unless transaction #todo confirm provisional status

    session[:current_url] = transaction.step2_url

    @data = hashify( transaction.step2_data )

    if params[:json]
      render json: @data
    else
      themed_render(embed, params)
    end
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
      themed_render(embed, params)
    end
  end

  def thanks
    embed = resolve_embed(params)
    return no_context  unless embed

    @transaction = Transaction.by_uuid(params[:transaction_uuid])
    # resolved_session_data = resolve_session_data(params)
    # used to redisplay after signup
    session[:current_url] = @transaction.finished_url

    transaction = Transaction.by_uuid(params[:transaction_uuid])

    @data = hashify( transaction.step2_data )  #todo: consider different view of data

    if params[:json]
      render json: @data
    else
      themed_render(embed, params)
    end
  end

  def merchant_receipt
    @embed = Embed.by_uuid(params[:uuid])
    @transaction = Transaction.by_uuid(params[:transaction_uuid])
    @data = hashify( @transaction.step2_data )  #todo: consider different view of data
    # render 'pay/merchant_receipt'
    #todo: figure out a way automatically fall back to default for individual actions
    themed_render(embed, params)
  end

  def terms
    embed = resolve_embed(params)
    themed_render(embed, params)
  end

  def faq
    embed = resolve_embed(params)
    themed_render(embed, params)
  end

  def privacy
    embed = resolve_embed(params)
    themed_render(embed, params)
  end

  def auth_failure
    puts "auth0 failure - params: #{params}"
    # assumes embed determined by hostname
    @error_msg = request.params['message']
    embed = TenantState.current_embed
    themed_render(embed, params)
  end

  protected

  def themed_render(embed, params, layout: 'application')
    @theme = embed.resolve_theme
    path = view_path(params[:action], embed)
    render path, layout: "#{Rails.root}/app/views/#{@theme}/layouts/#{layout}"
  end

  def resolve_embed(params)
    result = TenantState.current_embed
    unless result
      uuid = params[:uuid] || ENV['STANDALONE_EMBED_UUID']
      result = Embed.resolve(uuid, required: false)
    end
    result
  end

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

end
