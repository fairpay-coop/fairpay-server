# data specific to authentication.
# note, should probably be named 'Identity'
# todo: associate a user with a 'Realm' which can partition between authentication providers
# and logical sets of users

class User < ActiveRecord::Base

  # add_column :users, :auth_token, :string, index: true
  # add_column :users, :auth_token_created_at, :datetime  - note, not yet used
  # add_reference :users, :realm, index: true, foreign_key: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  belongs_to :realm

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

  def self.realm_find(realm, email)
    User.find_by(realm: realm, email: email)
  end

  def self.find_or_create(realm, email)
    result = realm_find(realm, email)
    unless result
      result = User.create!(realm: realm, email: email)
    end
    result
  end

  # devise hook
  def self.find_for_database_authentication(warden_conditions)
    puts "warden conditions: #{warden_conditions}"
    email = warden_conditions[:email]
    result = realm_find(TenantState.realm, email)
    puts "find for auth - result: #{result}"
    result
  end

  def self.new_with_session(params, session)
    puts "new with session - params: #{params}, session: #{session}"
    realm = TenantState.realm
    email = params[:email]
    Profile.find_or_create(realm, email)  # gurantee associated profile record exists
    params[:realm_id] = realm.id
    new(params)


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
