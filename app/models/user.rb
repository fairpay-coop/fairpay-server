class User < ActiveRecord::Base

  # add_column :users, :auth_token, :string, index: true
  # add_column :users, :auth_token_created_at, :datetime  - note, not yet used

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


  before_save :ensure_auth_token




  def ensure_auth_token
    if auth_token.blank?
      self.auth_token = generate_auth_token
    end
  end

  def profile
    Profile.find_by(email: email)
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
