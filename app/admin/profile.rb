ActiveAdmin.register Profile do

# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters

  permit_params :name, :first_name, :last_name, :email, :phone, :data_json

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
    column :name
    column :email
    actions
  end


  form do |f|
    f.inputs do
      f.input :name
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :phone
      f.input :data_json, as: :text
    end
    f.actions
  end


end
