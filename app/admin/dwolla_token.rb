ActiveAdmin.register DwollaToken do


  permit_params :account_id, :access_token, :refresh_token, :expires_in, :scope, :app_id, :profile_id

  index do
    selectable_column
    id_column
    column :profile
    column :account_id
    column :access_token
    column :updated_at
    column :created_at
    actions
  end

  # create_table :dwolla_tokens do |t|
  #   t.string :access_token
  #   t.string :refresh_token
  #   t.integer :expires_in
  #   t.string :scope
  #   t.string :app_id
  #   t.string :account_id
  #   t.timestamps null: false



end
