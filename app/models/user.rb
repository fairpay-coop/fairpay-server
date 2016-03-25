class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def profile
    Profile.find_by(email: email)
  end

  class Entity < Grape::Entity
    expose :id, :email
  end

end
