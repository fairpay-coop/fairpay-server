class Address < ActiveRecord::Base
  include DataFieldable
  include ApplicationHelper

  # create_table :addresses do |t|
  #   t.string :uuid, index: true  # identifier used by api
  #   t.string :kind   # mailing, billing, shipping
  #   t.string :label  # potentially user supplied label for specific address
  #   t.references :profile, index: true, foreign_key: true, null: false   # owning profile
  #   t.references :organization, index: true     # optionally associated organization
  #   t.string :first_name
  #   t.string :last_name
  #   t.string :organization_name
  #   t.string :street_address
  #   t.string :extended_address
  #   t.string :locality      # city
  #   t.string :region        # state
  #   t.string :postal_code
  #   t.string :country_code  # 2 letter iso code
  #   t.json   :data          # not currently used
  #   t.timestamps null: false


  belongs_to :profile
  belongs_to :organization, class_name: 'Profile'


  KINDS = {
      mailing: 'Mailing',
      billing: 'Billing',
      shipping: 'Shipping',
  }

  def self.kinds
    KINDS
  end

  def kind_name
    KINDS[kind_sym]
  end

  def payment_type
    kind_sym
  end

  def kind_sym
    kind.to_sym
  end

  def realm
    profile&.realm
  end


  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :first_name, :last_name, :organization_name, :street_address, :extended_address, :locality, :region, :postal_code, :kind, :label

  end

end
