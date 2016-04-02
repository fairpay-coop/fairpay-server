class PaymentSource < ActiveRecord::Base
  include DataFieldable

  # create_table :payment_sources do |t|
  #   t.references :profile, index: true, foreign_key: true
  #   t.references :merchant_config, index: true, foreigh_key: true
  #   t.string :source_key, index: true  - used when potentially sharable between merchant configs (i.e. dwolla tokens)
  #   t.string :kind
  #   t.json :data
  #   t.timestamps null: false


  belongs_to :profile

  attr_data_field :description
  attr_data_field :bin


  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :kind, :description, :bin
  end

  def represent
    Entity.represent(self)
  end

end
