class Auth0Controller < ApplicationController

  # layout 'default/site/application'

  def callback
    puts "auth0 callback - params: #{params}, request: #{request}"

    # example request.env['omniauth.auth'] in https://github.com/auth0/omniauth-auth0#auth-hash
    # id_token = session[:userinfo]['credentials']['id_token']
    # store the user profile in session and redirect to root
    userinfo = request.env['omniauth.auth']
    puts "userinfo: #{userinfo}"

    id_token = userinfo['credentials']['id_token']
    session[:auth_id_token] = id_token

    info = userinfo[:info]
    puts "info: #{info}"
    email = info[:email]
    name = info[:name]
    name = ''  if name == email  # blank out unknown name when native auth0 account used
    #name = name.split('@').first  if name.present? && name.include?('@')
    first_name = info[:first_name]
    last_name = info[:last_name]
    realm = TenantState.realm
    Profile.find_or_create(realm, email, name: name, first_name: first_name, last_name: last_name)
    # session[:authenticated_email] = email
    # note, need to use raw cookies to share state between api and rails controllers
    cookies[:authenticated_email] = {value: email, path: '/'}

    puts "cookies: #{cookies.to_json}"
    url = cookies[:next_step_url] || root_path
    redirect_to url
  end

  # note: moved to site_controller
  # def failure
  #   puts "auth0 failure - params: #{params}"
  #   # assumes embed determined by hostname
  #   @error_msg = request.params['message']
  #   embed = TenantState.current_embed
  #   themed_render(embed, params)
  # end


  def logout
    cookies.delete(:authenticated_email)
    cookies.delete(:next_step_url)
    # todo: track return url
    redirect_to root_path
  end

end
