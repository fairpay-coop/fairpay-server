class Profile < ActiveRecord::Base

  # create_table :profiles do |t|
  #   t.string :name
  #   t.string :email
  #   t.string :phone
  #   t.timestamps null: false


  has_many :merchant_configs
  has_many :embeds
  has_many :payment_sources
  # belongs_to :dwolla_token


  def has_dwolla_auth
    dwolla_payment_source&.get_data_field(:account_id).present?
  end

  def dwolla_payment_source(autocreate: true)
    if autocreate
      payment_sources.find_or_create_by(kind: :dwolla)
    else
      payment_sources.find_by(kind: :dwolla)
    end
  end

  def dwolla_token
    payment_source = dwolla_payment_source
    if payment_source
      account_id = payment_source.get_data_field(:account_id)
      DwollaToken.find_by_account_id(account_id)
    end
  end

  def associate_dwolla_account_id(account_id)
    payment_source = dwolla_payment_source(autocreate: true)
    payment_source.update_data_field(:account_id, account_id)
  end

end
