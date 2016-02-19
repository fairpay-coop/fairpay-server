class DwollaToken < ActiveRecord::Base


  # create_table :dwolla_tokens do |t|
  #   t.string :access_token
  #   t.string :refresh_token
  #   t.integer :expires_in
  #   t.string :scope
  #   t.string :app_id
  #   t.string :account_id
  #   t.timestamps null: false


  belongs_to :profile


  def token
    DwollaService.instance.token_for_data(self)
  end

  def refresh
    refreshed = DwollaService.instance.refresh(token)
    self.update!(access_token: refreshed.access_token)
    # need to make sure both local and persisted instances are updated
    self.access_token = refreshed.access_token
    # self.save!
  end

  def funding_sources
    DwollaService.instance.list_funding_sources(token)
  end

  def default_funding_source_uri
    funding_sources["Balance"]
  end

  def account_uri
    data = token.get("accounts/#{account_id}")
    data[:_links][:self][:href]
  end

  def make_payment(payee_dwolla_token, amount)
    # access tokens expire after 1 hour.  for now assume always needs refreshing before any transaction
    self.refresh
    puts "access token before refresh: #{payee_dwolla_token.access_token}"
    payee_dwolla_token.refresh
    puts "access token after refresh: #{payee_dwolla_token.access_token}"
    DwollaService.instance.make_payment(self.token, self.default_funding_source_uri, payee_dwolla_token.account_uri, amount)
  end

end
