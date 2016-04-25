class AbuntooController < ApplicationController
  include ApplicationHelper

  layout 'abuntoo'

  def index
    uuid = ENV['STANDALONE_EMBED_UUID']
    embed = Embed.find_by_uuid(uuid)
    raise "embed data not found for STANDALONE_EMBED_UUID: #{uuid}"  unless embed
    embed_params = {} # not relevant for now
    @data = hashify( embed.embed_data(embed_params) )
  end

  def terms
  end

  def privacy
  end

end
