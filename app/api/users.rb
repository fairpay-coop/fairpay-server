class Users < Grape::API

  resource :users do

    # shouldn't expose any of this level of data until we have a security model
    desc 'Return all the users.'
    get do
      present User.all
    end

    post :signin do
      puts "signin - params: #{params.inspect}"

      params do
        required :email, type: String
        required :password, type: String
        #todo: think about a better way to slice this api
        optional :transaction_uuid, type: String  # optionally indicated a transaction to updated as 'profile_authenticated'
      end
      email = params[:email]
      password = params[:password]

      user = User.find_by_email(email)
      raise "user not found for email"  unless user
      raise "invalid password"  unless user.valid_password?(password)

      result = user.auth_token
      wrap_result( result )
    end


    post :signup do
      puts "signup - params: #{params.inspect}"

      params do
        required :email, type: String
        required :password, type: String
      end
      email = params[:email]
      password = params[:password]

      user = User.find_by_email(email)
      raise "user already exists"  if user
      user = User.create!({email: email, password: password, password_confirmation: password})

      result = user.auth_token
      wrap_result( result )
    end

    # tests if user exists for given email
    get :exists do
      puts "exists - params: #{params.inspect}"
      params do
        required :email, type: String
      end
      email = params[:email]
      user = User.find_by_email(email)
      result = user.present?
      wrap_result( result )
    end

    get :profile do
      authenticate!
      result = Profile::Entity.represent(authenticated_user.profile)
      wrap_result( result )
    end


  end

end
