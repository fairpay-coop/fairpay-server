class AbuntooController < ApplicationController
  include ApplicationHelper

  def index
    uuid = ENV['STANDALONE_EMBED_UUID']
    embed = Embed.find_by_uuid(uuid)
    raise "embed data not found for STANDALONE_EMBED_UUID: #{uuid}"  unless embed
    embed_params = {} # not relevant for now
    @data = hashify( embed.embed_data(embed_params) )
    @raw_embed = embed  # might be useful for now, remove later

    render 'index', layout: nil
  end

end
