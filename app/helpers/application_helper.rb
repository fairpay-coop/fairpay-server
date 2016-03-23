module ApplicationHelper

  # want to guarantee a consistent hostname is used
  # duplicated logic from PaypalService - todo: better home for this?
  def base_url
    @base_url || ENV['BASE_URL']
  end



  def amount_param(attr)
    puts "amount param - params: #{params.inspect}"
    raw = params[attr]
    if raw.present?
      raw.to_f  #todo: what is the best native type for a two digit precision amount?
    else
      nil
    end
  end


  def format_amount(amount, decimals=2)
    "%.#{decimals}f" % amount
  end

  #todo: figure out better way to include in ActionMailer rendered views
  def self.format_amount(amount, decimals=2)
    "%.#{decimals}f" % amount
  end


end
