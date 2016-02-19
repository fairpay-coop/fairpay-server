class Profile < ActiveRecord::Base

  # create_table :profiles do |t|
  #   t.string :name
  #   t.string :email
  #   t.string :phone
  #   t.timestamps null: false


  has_many :merchant_configs
  has_many :embeds
  has_one :dwolla_token


  def has_dwolla_auth
    dwolla_token.present?
  end

  # def dwolla_token
  #   # DwollaService.instance.token_for_profile_id(id)
  # end

end
