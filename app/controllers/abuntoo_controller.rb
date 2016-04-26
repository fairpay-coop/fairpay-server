class AbuntooController < PayController
  include ApplicationHelper

  layout 'abuntoo'

  def index
    uuid = resolve_embed_uuid
    embed = Embed.find_by_uuid(uuid)
    raise "embed data not found for STANDALONE_EMBED_UUID: #{uuid}"  unless embed
    embed_params = {} # not relevant for now
    @data = hashify( embed.embed_data(embed_params) )
  end

  def donate
    embed_uuid = resolve_embed_uuid #params[:uuid]
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

  def payment
    # embed = Embed.by_uuid(params[:uuid])
    transaction = Transaction.by_uuid(params[:transaction_uuid])
    raise "invalid transaction id: #{params[:transaction_uuid]}" unless transaction #todo confirm provisional status
    session[:current_url] = transaction.step2_url

    @data = hashify( transaction.step2_data )

    if params[:json]
      render json: @data
    else
      @data
    end
  end

  def thanks
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

  def terms
  end

  def privacy
  end

  protected

  def resolve_embed_uuid
    ENV['STANDALONE_EMBED_UUID']
  end

end
