class WelcomeController < ApplicationController

  def no_context
  end

  def test
    @embeds = Embed.where(disabled: false)
  end

end
