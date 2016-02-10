class API < Grape::API
  version 'v1', using: :path
  format :json

  helpers do
    def declared_params(except: [])
      declared(params, include_missing: false).reject {|k,v| except.include?(k.to_sym) || except.include?(k.to_s)}
    end
  end

  rescue_from Grape::Exceptions::ValidationErrors do |e|
    handler = lambda {|arg| error_response(arg)}
    exec_handler(e, &handler)
  end

  rescue_from :all do |e|
    Rails.logger.error("\n\n#{e.class.name} - #{e.message}:\n   " +
                           Rails.backtrace_cleaner.clean(e.backtrace).join("\n   "))
    error_response({ message: "rescued from #{e.class.name}" })
  end


  mount Users => '/'

  add_swagger_documentation(
      base_path: "/api",
      api_version: 'v1',
      hide_documentation_path: true
  )

end
