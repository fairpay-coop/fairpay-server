class Profile < ActiveRecord::Base
  include DataFieldable

  # create_table :profiles do |t|
  #   t.string :name
  #   t.string :email
  #   t.string :phone
  #   t.timestamps null: false
  # add_column :profiles, :first_name, :string
  # add_column :profiles, :last_name, :string
  # add_column :profiles, :data, :json
  # add_reference :profiles, :realm, index: true, foreign_key: true


  has_many :merchant_configs
  has_many :embeds
  has_many :campaigns
  has_many :payment_sources
  has_many :addresses
  belongs_to :realm


  def display_name
    name || ("#{first_name} #{last_name}")
  end


  def user
    User.find_by(email: email)
  end

  def self.find_or_create(realm, email, name: email)
    result = Profile.find_by(realm: realm, email: email)
    unless result
      name = email  unless name.present?  # don't require 'name' as the api level, default to email
      result = Profile.create!(realm: realm, email: email, name: name)
    end
    result
  end


  #todo: rip out all usages.  migrate to mechant config or type/key
  def payment_source_for_type(type, autocreate: true)  # todo: make this default false
    if autocreate
      # unless payment_sources.find_by(kind: type)
      #   puts "autocreating payment source"
      #   puts caller.join("\n")
      # end
      payment_sources.find_or_create_by(kind: type)
    else
      payment_sources.find_by(kind: type)
    end
  end

  def payment_source_for_merchant_config(merchant_config, autocreate: false)
    if autocreate
      payment_sources.find_or_create_by(merchant_config: merchant_config)
    else
      payment_sources.find_by(merchant_config: merchant_config)
    end
  end

  def payment_source_for_type_key(type, source_key, autocreate: false)
    if autocreate
      payment_sources.find_or_create_by(kind: type, source_key: source_key)
    else
      payment_sources.find_by(kind: type, source_key: source_key)
    end
  end


  def submit_address(address_data)
    puts "profile.submit_address: #{address_data.inspect}"
    #future: support labels, for now assumes one address per type
    # existing = addresses.where(kind: address_data[:kind])
    existing = addresses.first #where(kind: address_data[:kind])
    if existing.present?
      existing.update!(address_data)
    else
      addresses.create!(address_data)
    end
  end


  # def has_dwolla_auth
  #   dwolla_payment_source(autocreate:false)&.get_data_field(:account_id).present?
  # end

  def dwolla_payment_source(client_id, autocreate: false)
    payment_source_for_type_key(:dwolla, client_id, autocreate: autocreate)
  end

  # def dwolla_token
  #   payment_source = dwolla_payment_source
  #   if payment_source
  #     account_id = payment_source.get_data_field(:account_id)
  #     DwollaToken.find_by_account_id(account_id)
  #   end
  # end

  # def associate_dwolla_account_id(account_id)
  #   payment_source = dwolla_payment_source(autocreate: true)
  #   payment_source.update_data_field(:account_id, account_id)
  # end

  #todo: revisit
  def first_name
    words = name&.split(" ") || []
    words.first
  end

  def last_name
    words = name&.split(" ") || []
    words.last
  end

  def has_user
    user.present?
  end

  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :name, :email, :phone, :has_user
    # expose :address, using: Address::Entity
  end

end
