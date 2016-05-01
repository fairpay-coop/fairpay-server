Rails.application.config.middleware.use OmniAuth::Builder do
  # todo: support multiple user realms and auth0 provider configs
  auth0_config = MerchantConfig.where(kind: 'auth0').first
  provider(
    :auth0,
    auth0_config.get_data_field(:client_id),
    auth0_config.get_data_field(:client_secret),
    auth0_config.get_data_field(:domain),
    callback_path: "/auth/auth0/callback"
  )

  # provider(
  #   :auth0,
  #   ENV["AUTH0_CLIENT_ID"],
  #   ENV["AUTH0_CLIENT_SECRET"],
  #   ENV["AUTH0_DOMAIN"],
  #   callback_path: "/auth/auth0/callback"
  # )
end
