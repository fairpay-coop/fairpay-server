class WelcomeController < ApplicationController

  def index
    @embeds = Embed.where(disabled: false)
  end

end
