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

  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :data, :kind
  end

  def represent
    # todo: clean this up once data_field refactored to expose natural getters
    {
        description: get_data_field(:description),
        bin: get_data_field(:bin)
    }
    # Entity.represent(self)
  end

end
