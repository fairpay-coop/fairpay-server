ActiveAdmin.register MerchantConfig do

  permit_params :profile_id, :name, :internal_name, :kind, :data, :disabled


  index do
    selectable_column
    id_column
    column :profile
    column :name
    column :internal_name
    column :kind
    column :updated_at
    column :disabled
    actions
  end


  form do |f|
    f.inputs do
      f.input :profile, as: :select, collection: Profile.pluck(:name, :id)

      f.input :name
      f.input :internal_name

      f.input :kind, as: :select, collection: MerchantConfig.kinds.map { |key,name| [name, key] }

      f.input :data, as: :text

      # todo: integrate friendlier json editor
      # https://lorefnon.me/2015/03/02/dealing-with-json-fields-in-active-admin.html
      # f.input :data, as: :text, input_html: { class: 'jsoneditor-target' }

      f.input :disabled
    end
    f.actions
  end

end
