module ApplicationHelper

  # want to guarantee a consistent hostname is used
  # duplicated logic from PaypalService - todo: better home for this?
  def base_url
    @base_url || ENV['BASE_URL']
  end



  def amount_param(params, attr)
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

  def resolve_current_user(session_data)
    if session_data
      if session_data[:auth_token].present?
        user = User.find_by(auth_token: session_data[:auth_token])
        puts "auth token user: #{user}"
        return user
      end

      if session_data[:authenticated_user]
        return session_data[:authenticated_user]
      else
        email = session_data[:email]  #todo: widget auth'd cookie support
        return User.find_by_email(email)  if email
      end
    end
    nil
  end

  def resolve_current_profile(session_data)
    user = resolve_current_user(session_data)
    user.profile  if user
  end

  def session_auth_token
    current_user&.auth_token
  end

  #force all object representations into hashes.  todo: does this utility already exist?
  def hashify(obj)
    JSON.parse(obj.to_json).with_indifferent_access
  end

end
