class Users::RegistrationsController < Devise::RegistrationsController
# before_filter :configure_sign_up_params, only: [:create]
# before_filter :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    puts "create - params: #{params.inspect}"
    params["user[password_confirmation]"] = params["user[password]"]
    # session[:finished_url] = params[:finished_url]
    # @finished_url = params[:finished_url]
    # super
    super_create
  end


  # not sure why. but didn't seem to be logged in after signup until copying this method here
  def super_create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      puts "persisted"
      if resource.active_for_authentication?
        puts "active for auth - finished url - session: #{session[:finished_url]}, var: #{@finished_url}"
        set_flash_message :notice, :signed_up
        puts "resource name: #{resource_name.inspect} - resource: #{resource.inspect}"
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        puts "inactive for auth"
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      put "redisplay"
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end


  def after_sign_up_path_for(resource)
    # puts "after signup path - #{session[:finished_url]} - var: #{@finished_url}"
    current_url == session[:current_url]
    puts "after signup path - current url: #{current_url}"
    current_url || super
  end


# GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.for(:sign_up) << :attribute
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.for(:account_update) << :attribute
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
