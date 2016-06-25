ActiveAdmin.register Profile do

# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters

  permit_params :name, :first_name, :last_name, :email, :phone, :data_json, :realm_id, :primary_address

#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if resource.something?
#   permitted
# end

  index do
    selectable_column
    id_column
    column :realm
    column :name
    column :email
    column :primary_address
    actions
  end

  filter :realm
  filter :email

  show do
    attributes_table do
      row :name
      row :first_name
      row :last_name
      row :email
      row :phone
      row :receipt_name
      row :tax_id
      row :postal_code
      row :website
      row :bio
      row :primary_address
      row :data
      row :realm
    end
  end

  form do |f|
    f.inputs do
      # f.input :user, as: :select, collection: User.pluck(:email, :email)
      f.input :realm, as: :select, collection: Realm.pluck(:name, :id)
      f.input :name
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :phone
      # f.input :primary_address #, input_html: {disabled: true}
      f.input :data_json, as: :text
    end
    f.actions
  end


end
