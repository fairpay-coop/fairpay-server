ActiveAdmin.register MerchantConfig do

# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters

permit_params :profile_id, :kind, :data


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
    # f.input :profile_id
    f.input :profile, as: :select, collection: Profile.pluck(:name, :id)
    # f.input :profile, as: :select, collection: Profile.all.map { |a| [a.name, a.id] }

    f.input :kind, as: :select, collection: MerchantConfig.kinds.map { |key,name| [name, key] }

    f.input :data, as: :text
    # todo: integrate friendlier json editor
    # https://lorefnon.me/2015/03/02/dealing-with-json-fields-in-active-admin.html
    # f.input :data, as: :text, input_html: { class: 'jsoneditor-target' }

  end
  f.actions
end

end
