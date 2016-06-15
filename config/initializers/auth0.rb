Rails.application.config.middleware.use OmniAuth::Builder do
  # todo: support multiple user realms and auth0 provider configs
  # beware, this code broke the ability to run the 'rake db:' commands since it tries to
  # executed before running the rake tasks
  # auth0_config = MerchantConfig.where(kind: 'auth0').first
  # if auth0_config
  #   provider(
  #     :auth0,
  #     auth0_config.get_data_field(:client_id),
  #     auth0_config.get_data_field(:client_secret),
  #     auth0_config.get_data_field(:domain),
  #     callback_path: "/auth/auth0/callback"
  #   )
  # end

  provider(
    :auth0,
    ENV["AUTH0_CLIENT_ID"],
    ENV["AUTH0_CLIENT_SECRET"],
    ENV["AUTH0_DOMAIN"],
    callback_path: "/auth/auth0/callback"
  )
end
