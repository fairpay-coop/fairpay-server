ActiveAdmin.register PaymentSource do

  permit_params :profile_id, :kind, :name, :data


  index do
    selectable_column
    id_column
    column :profile
    column :kind
    column :updated_at
    actions
  end


  form do |f|
    f.inputs do
      f.input :profile, as: :select, collection: Profile.pluck(:name, :id)

      # f.input :kind, as: :select, collection: MerchantConfig.kinds.map { |key,name| [name, key] }
      f.input :name

      f.input :data, as: :text
    end
    f.actions
  end

end
