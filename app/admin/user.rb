ActiveAdmin.register User do

# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if resource.something?
#   permitted
# end

  permit_params :email, :realm_id
  # :password, :password_confirmation, :auth_token,


    index do
    selectable_column
    id_column
    column :realm
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  filter :realm
  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  form do |f|
    f.inputs "Admin Details" do
      f.input :realm, as: :select, collection: Realm.pluck(:name, :id)
      f.input :email

      # f.input :password
      # f.input :password_confirmation
      # f.input :auth_token
    end
    f.actions
  end



end
