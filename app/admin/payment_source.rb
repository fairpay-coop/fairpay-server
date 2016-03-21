ActiveAdmin.register PaymentSource do

  permit_params :profile_id, :kind, :source_key, :name, :data_json


  index do
    selectable_column
    id_column
    column :profile
    column :kind
    column :source_key
    column :updated_at
    actions
  end


  form do |f|
    f.inputs do
      f.input :profile, as: :select, collection: Profile.pluck(:name, :id)

      f.input :kind, as: :select, collection: MerchantConfig.kinds.map { |key,name| [name, key] }
      f.input :source_key
      f.input :name

      f.input :data_json, as: :text
    end
    f.actions
  end

end
