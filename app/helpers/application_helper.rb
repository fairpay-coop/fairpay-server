module ApplicationHelper

  # want to guarantee a consistent hostname is used
  # duplicated logic from PaypalService - todo: better home for this?
  def base_url
    @base_url || ENV['BASE_URL']
  end


end
