class Auth0Controller < ApplicationController

  layout 'abuntoo'

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
    Profile.find_or_create(email: email, name: name)
    # session[:authenticated_email] = email
    # note, need to use raw cookies to share state between api and rails controllers
    cookies[:authenticated_email] = {value: email, path: '/'}

    puts "cookies: #{cookies.to_json}"
    url = cookies[:next_step_url] || root_path
    redirect_to url
  end

  def failure
    puts "auth0 failure - params: #{params}"
    @error_msg = request.params['message']
  end


  def logout
    session.delete(:authenticated_email)
    cookies.delete(:authenticated_email_cookie)
    # todo: track return url
    redirect_to root_path
  end

end
