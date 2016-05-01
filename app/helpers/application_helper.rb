module ApplicationHelper

  # want to guarantee a consistent hostname is used
  # duplicated logic from PaypalService - todo: better home for this?
  def base_url
    # @base_url || ENV['BASE_URL']
    # maintain the request url
    TenantState.current_host || ENV['BASE_URL']
  end


  def view_path(tail, embed, base: 'site')
    "#{base}/#{resolve_theme(embed)}/#{tail}"
  end

  # either render a referenced partial or an html blob
  def render_content(content, embed)
    if content.starts_with?('partial:')
      partial = content.sub('partial:', '')
      render view_path("content/#{partial}", embed), embed: embed
    else
      content.html_safe
    end
  end

  def resolve_theme(embed)
    if embed.is_a?(Embed)
      embed.resolve_theme
    else
      # assume in hash format
      embed[:theme]
    end
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

  # def resolve_current_user(session_data)
  #   if session_data
  #     if session_data[:auth_token].present?
  #       user = User.find_by(auth_token: session_data[:auth_token])
  #       puts "auth token user: #{user}"
  #       return user
  #     end
  #
  #     if session_data[:authenticated_user]
  #       return session_data[:authenticated_user]
  #     else
  #       email = session_data[:email]  #todo: widget auth'd cookie support
  #       return User.find_by_email(email)  if email
  #     end
  #   end
  #   nil
  # end

  def resolve_authenticated_profile(session_data)
    authenticated_email = session_data ? session_data[:authenticated_email] : nil
    if authenticated_email
      # handle the flow with an auth0 authenticated session
      realm = TenantState.realm
      return Profile.find_or_create(realm, authenticated_email)
    else
      # the api auth token flow
      auth_token = session_data ? session_data[:auth_token] : nil
      resolve_profile_from_token(auth_token)
    end
  end

  def resolve_profile_from_token(auth_token)
    if auth_token.present?
      user = User.find_by(auth_token: auth_token)
      puts "auth token user: #{user}"
      if user
        user.profile
      else
        puts "users not found for auth_token: #{auth_token}"
        nil
      end
    else
      nil
    end
  end

  def session_auth_token
    current_user&.auth_token
  end

  def auth0_signed_in
    auth0_authenticated_email.present?
  end

  def auth0_user
    email = auth0_authenticated_email
    if email
      realm = TenantState.realm
      user = User.find_or_create(realm, email)
      unless user
      end
    end
  end

  def auth0_profile
    email = auth0_authenticated_email
    realm = TenantState.realm
    Profile.find_or_create(realm, email)  if email
  end

  def auth0_authenticated_email
    cookies[:authenticated_email]
  end

  #force all object representations into hashes.  todo: does this utility already exist?
  def hashify(obj)
    JSON.parse(obj.to_json).with_indifferent_access
  end

end
