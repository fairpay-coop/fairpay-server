class API < Grape::API
  version 'v1', using: :path
  format :json

  helpers do
    def declared_params(except: [])
      declared(params, include_missing: false).reject {|k,v| except.include?(k.to_sym) || except.include?(k.to_s)}
    end

    # todo: figure out better way to automatically apply this wrapper to all responses
    def wrap_result(result)
      { result: result }
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
    # error_response({ message: "rescued from #{e.class.name}" })
    error!( {error: {code: 100, message: e.message} }, 200 )
  end

  # what does the => '/' imply here?  it seems like any other path here completely breaks things, and it doesn't seem to be needed
  mount Users  #=> '/'
  mount Embeds

  add_swagger_documentation(
      base_path: "/api",
      api_version: 'v1',
      hide_documentation_path: true
  )

end
