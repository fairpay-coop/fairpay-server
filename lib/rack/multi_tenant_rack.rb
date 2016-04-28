class TenantState
  def self.current_host= host
    Thread.current[:current_host] = host
  end

  def self.current_host
    Thread.current[:current_host]
  end

  def self.current_embed= embed
    Thread.current[:current_embed] = embed
  end

  def self.current_embed
    Thread.current[:current_embed]
  end
end

module Rack
  class MultiTenantRack

    def initialize app
      @app = app
    end

    def call env
      # get params in a nice format
      #post_params = Rack::Utils.parse_query(env['rack.input'].read, "&")
      #get_params  = Rack::Utils.parse_query(env['QUERY_STRING'],    "&")

      current_host = "#{env["rack.url_scheme"]}://#{env["HTTP_HOST"]}"
      puts "current host from env: #{current_host}"

      request = Rack::Request.new(env)
      server_name = Utils.unescape(env["SERVER_NAME"])
      puts "server name: #{server_name}"

      embed = Embed.resolve_from_host(server_name)
      puts "resolved embed: #{embed}"

      begin
        TenantState.current_host = current_host
        TenantState.current_embed = embed

        Thread.current[:server_name] = server_name
        req = Rack::Request.new(env)
        Thread.current[:request] = req

        @app.call env

      ensure
        Thread.current[:request] = nil
        Thread.current[:server_name] = nil
        TenantState.current_embed = nil
        TenantState.current_host = nil
      end

    end
  end
end
