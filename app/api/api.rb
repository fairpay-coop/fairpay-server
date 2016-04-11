class API < Grape::API
  version 'v1', using: :path
  format :json

  helpers do
    def declared_params(except: [])
      declared(params, include_missing: false).reject {|k,v| except.include?(k.to_sym) || except.include?(k.to_s)}
    end

    def wrap_result(result)
      { result: result }
    end

    # for now lives in BasePaymentService
    # def resolve_current_user(session_data)
    #   email = session_data[:email]
    #   Profile.find_by_email(email)  if email
    # end

    def authenticate!
      error!('Unauthorized. Invalid or expired token.', 401) unless authenticated_user
    end

    def authenticated_user
      token = headers['X-Auth-Token']
      @authenticated_user ||= User.find_by_auth_token(token) if token
    end

    include ApplicationHelper
  end

  rescue_from Grape::Exceptions::ValidationErrors do |e|
    handler = lambda {|arg| error_response(arg)}
    exec_handler(e, &handler)
  end

  rescue_from :all do |e|
    Rails.logger.error("\n\n#{e.class.name} - #{e.message}:\n   " +
                           Rails.backtrace_cleaner.clean(e.backtrace).join("\n   "))
    # note, using a 200 response code so that formatted error message is passed through to ajax 'success' handler instead of 'error' handler
    error!( {error: {code: 100, message: e.message} }, 200 )
  end

  mount Users
  mount Embeds

  add_swagger_documentation(
      base_path: "/api",
      api_version: 'v1',
      hide_documentation_path: true
  )

end
