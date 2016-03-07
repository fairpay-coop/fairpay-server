class Profile < ActiveRecord::Base

  # create_table :profiles do |t|
  #   t.string :name
  #   t.string :email
  #   t.string :phone
  #   t.timestamps null: false
  # add_column :profiles, :first_name, :string
  # add_column :profiles, :last_name, :string


  has_many :merchant_configs
  has_many :embeds
  has_many :payment_sources
  # belongs_to :dwolla_token


  def display_name
    name || ("#{first_name} #{last_name}")
  end

  def payment_source_for_type(type, autocreate: true)
    if autocreate
      payment_sources.find_or_create_by(kind: type)
    else
      payment_sources.find_by(kind: type)
    end
  end



  def has_dwolla_auth
    dwolla_payment_source&.get_data_field(:account_id).present?
  end

  def dwolla_payment_source(autocreate: true)
    payment_source_for_type(:dwolla, autocreate: autocreate)
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

  #todo: revisit
  def first_name
    words = name&.split(" ") || []
    words.first
  end

  def last_name
    words = name&.split(" ") || []
    words.last
  end

end
