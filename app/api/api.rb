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

    include ApplicationHelper
  end

  rescue_from Grape::Exceptions::ValidationErrors do |e|
    handler = lambda {|arg| error_response(arg)}
    exec_handler(e, &handler)
  end

  rescue_from :all do |e|
    Rails.logger.error("\n\n#{e.class.name} - #{e.message}:\n   " +
                           Rails.backtrace_cleaner.clean(e.backtrace).join("\n   "))
    error!( {error: {code: 100, message: e.message} }, 500 )
  end

  mount Users
  mount Embeds

  add_swagger_documentation(
      base_path: "/api",
      api_version: 'v1',
      hide_documentation_path: true
  )

end
