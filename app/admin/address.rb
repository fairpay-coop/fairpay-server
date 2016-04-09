ActiveAdmin.register Address do


  permit_params :first_name, :last_name, :organization_name, :street_address, :extended_address, :locality, :region, :postal_code, :country_code, :kind, :label

  index do
    selectable_column
    id_column
    column :profile
    column :kind
    column :label
    column :first_name
    column :last_name
    column :street_address
    column :city
    column :updated_at
    actions
  end


  form do |f|
    f.inputs do
      f.input :profile, as: :select, collection: Profile.pluck(:name, :id)
      f.input :kind
      f.input :label
      f.input :first_name
      f.input :last_name
      f.input :organization_name
      f.input :street_address
      f.input :extended_address
      f.input :locality
      f.input :region
      f.input :postal_code
      f.input :country_code
      # f.input :data_json, as: :text
    end
    f.actions
  end


end
