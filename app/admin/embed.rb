ActiveAdmin.register Embed do

  permit_params :profile_id, :campaign_id, :name, :internal_name, :kind, :data_json, :disabled


  index do
    selectable_column
    id_column
    column :uuid
    column :profile
    column :campaign
    column :name
    column :internal_name
    # column :kind
    column :disabled
    column :updated_at
    actions
  end


  form do |f|
    f.inputs do
      f.input :profile, as: :select, collection: Profile.pluck(:name, :id)
      f.input :campaign, as: :select, collection: Campaign.pluck(:name, :id)

      # f.input :kind, as: :select, collection: Embed.kinds.map { |key,name| [name, key] }
      f.input :name
      f.input :internal_name

      f.input :data_json, as: :text

      # todo: integrate friendlier json editor
      # https://lorefnon.me/2015/03/02/dealing-with-json-fields-in-active-admin.html
      # f.input :data, as: :text, input_html: { class: 'jsoneditor-target' }

      f.input :disabled

    end
    f.actions
  end

end
