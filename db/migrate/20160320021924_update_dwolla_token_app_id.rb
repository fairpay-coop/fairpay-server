class UpdateDwollaTokenAppId < ActiveRecord::Migration

  def change
    add_column :dwolla_tokens, :client_id, :string
    DwollaToken.update_all(client_id: ENV['DWOLLA_CLIENT_ID'])
  end


  # def up
  #   # add_column :dwolla_tokens, :client_id, :string
  #
  #   # update existing records with system default client_id
  #   DwollaToken.update_all(client_id: ENV['DWOLLA_CLIENT_ID'])
  # end
  #
  # def down
  # end

end
