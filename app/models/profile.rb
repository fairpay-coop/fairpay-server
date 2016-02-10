class Profile < ActiveRecord::Base

  # create_table :profiles do |t|
  #   t.string :name
  #   t.string :email
  #   t.string :phone
  #   t.timestamps null: false


  has_many :merchant_configs
  has_many :embeds

end
