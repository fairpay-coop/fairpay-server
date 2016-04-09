class AddAuthTokenToUser < ActiveRecord::Migration
  def change
    add_column :users, :auth_token, :string, index: true
    add_column :users, :auth_token_created_at, :datetime
  end
end
