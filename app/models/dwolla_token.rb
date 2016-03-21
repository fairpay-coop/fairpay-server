class DwollaToken < ActiveRecord::Base


  # create_table :dwolla_tokens do |t|
  #   t.string :access_token
  #   t.string :refresh_token
  #   t.integer :expires_in
  #   t.string :scope
  #   t.string :app_id    - note, not clear if this was supposed to equivalent to client_id or not, was not automatically populated.  ignoring and using our own 'client_id' column
  #   t.string :account_id
  #   t.timestamps null: false
  #   t.reference :profile, index: true, foreign_key: true
  #   t.string :client_id


  # has_many :profile
  has_many :payment_sources

  def stale_token?
    access_token.blank? || self.updated_at.blank? || Time.now.ago(1.hour) > self.updated_at
  end

  def token(service)
    refresh(service)  if stale_token?
    raw_token(service)
  end

  def raw_token(service)
    service.token_for_data(self)
  end

  def refresh(service)
    refreshed = service.refresh_raw_token(raw_token(service))
    self.update!(access_token: refreshed.access_token)
    # need to make sure both local and persisted instances are updated
    self.access_token = refreshed.access_token
    self.updated_at = Time.now
    # self.save!
  end

  def funding_sources(service, amount = nil)
    service.list_funding_sources(token(service), amount)
  end

  def default_funding_source_uri(service)
    funding_sources(service)["Balance"]
  end

  def account_uri(service)
    data = token(service).get("accounts/#{account_id}")
    data[:_links][:self][:href]
  end

  # def make_payment(payee_dwolla_token, amount)
  #   # access tokens expire after 1 hour.  for now assume always needs refreshing before any transaction
  #   # self.refresh
  #   puts "access token before refresh: #{payee_dwolla_token.access_token}"
  #   # payee_dwolla_token.refresh
  #   puts "access token after refresh: #{payee_dwolla_token.access_token}"
  #   DwollaService.instance.make_payment(self.token, self.default_funding_source_uri, payee_dwolla_token.account_uri, amount)
  # end

end
