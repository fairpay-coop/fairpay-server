class WelcomeController < ApplicationController

  def index
    @embeds = Embed.all
  end

end
