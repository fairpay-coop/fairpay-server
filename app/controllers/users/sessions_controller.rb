 class Users::SessionsController < Devise::SessionsController
# before_filter :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.for(:sign_in) << :attribute
  # end


  def after_sign_in_path_for(resource_or_scope)
    # stored_location_for(resource_or_scope) || signed_in_root_path(resource_or_scope)

    # puts "after signup path - #{session[:finished_url]} - var: #{@finished_url}"
    current_url = session[:current_url]    #todo: figure out the right time to reset this state
    puts "after sign in path - current url: #{current_url}"
    current_url || super

  end


  def after_sign_out_path_for(resource_or_scope)
    # scope = Devise::Mapping.find_scope!(resource_or_scope)
    # router_name = Devise.mappings[scope].router_name
    # context = router_name ? send(router_name) : self
    # context.respond_to?(:root_path) ? context.root_path : "/"

    #todo - figure out a clever way to save the current url after logout.  probably need to use a cookie

    current_url = session[:current_url]
    puts "after sign out path - current url: #{current_url}"
    current_url || super

  end


end
