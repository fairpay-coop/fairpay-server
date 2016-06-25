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
  has_many :payment_sources, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_one :primary_address, class_name: 'Address', foreign_key: :profile_id
  belongs_to :realm

  attr_data_field :receipt_name # for payee profile, used for payment receipt
  attr_data_field :tax_id  # for payee profile, used for payment receipt
  attr_data_field :bio
  attr_data_field :website
  attr_data_field :postal_code  #todo, link profile zip to associated address

  before_destroy :prune_dependent_ref


  def display_name
    # name || full_name
    if name.present?
      name
    elsif first_name.present? || last_name.present?
      "#{first_name} #{last_name}".strip
    else
      email
    end
  end

  def resolve_first_name
    return first_name  if first_name.present?
    if name.present?
      parts = name.split(' ')
      return parts.first
    else
      email_name = email.split('@').first
      return email_name.split('.').first
    end
  end

  def resolve_last_name
    return last_name  if last_name.present?
    if name.present?
      parts = name.split(' ')
      return parts.last
    else
      email_name = email.split('@').first
      return email_name.split('.').last
    end
  end

  def user
    User.find_by(email: email)
  end

  def self.find_or_create(realm, email, name: nil, first_name: nil, last_name: nil)
    raise "email required"  if email.blank?
    result = Profile.find_by(realm: realm, email: email)
    unless result
      name = email.split('@').first  unless name.present?  # don't require 'name' as the api level, default to email
      result = Profile.create!(realm: realm, email: email, name: name, first_name: first_name, last_name: last_name)
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

  # def primary_address
  #   addresses.first
  # end

  def submit_address(address_data)
    puts "profile.submit_address: #{address_data.inspect}"
    #future: support labels, for now assumes one address per type
    # existing = addresses.where(kind: address_data[:kind])
    existing = primary_address #where(kind: address_data[:kind])
    if existing.present?
      existing.update!(address_data)
    else
      addresses.create!(address_data)
    end
  end

  def has_saved_payment_source?
    saved_payment_source.present?
  end

  def remove_saved_payment_source
    saved_payment_source.destroy
  end

  def saved_payment_source
    # for now assume only one relevant saved payment source
    payment_sources.first
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
  # def first_name
  #   words = name&.split(" ") || []
  #   words.first
  # end
  #
  # def last_name
  #   words = name&.split(" ") || []
  #   words.last
  # end

  def has_user
    user.present?
  end

  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :name, :email, :phone, :has_user, :first_name, :last_name, :receipt_name, :tax_id
    # expose :address, using: Address::Entity
  end


  private

  def prune_dependent_ref
    Transaction.where(payor: self).each do |tran|
      tran.update(payor: nil)
    end
    Transaction.where(payee: self).each do |tran|
      tran.update(payee: nil)
    end
  end


end
