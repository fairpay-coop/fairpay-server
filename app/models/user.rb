# data specific to authentication.
# note, should probably be named 'Identity'
# todo: associate a user with a 'Realm' which can partition between authentication providers
# and logical sets of users

class User < ActiveRecord::Base

  # add_column :users, :auth_token, :string, index: true
  # add_column :users, :auth_token_created_at, :datetime  - note, not yet used

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


  before_save :ensure_auth_token


  def ensure_persisted_auth_token
    if auth_token.blank?
      ensure_auth_token
      save!
    end
    auth_token
  end


  def ensure_auth_token
    if auth_token.blank?
      self.auth_token = generate_auth_token
    end
  end

  def profile
    Profile.find_by(email: email)
  end


  def self.find_or_create(email: nil)
    result = User.find_by(email: email)
    unless result
      result = User.create!(email: email)
    end
    result
  end


  class Entity < Grape::Entity
    expose :id, :email
  end


  private

  def generate_auth_token
    loop do
      token = Devise.friendly_token
      break token  unless User.where(auth_token: token).first
    end
  end



end
