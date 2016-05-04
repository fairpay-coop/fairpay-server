ActiveAdmin.register Embed do

  permit_params :profile_id, :campaign_id, :name, :internal_name, :kind, :data_json, :disabled, :realm_id
                # :payment_types, :mailing_list, :recurrence, :suggested_amounts, :fee_allocations,
                # :capture_memo, :consider_this, :amount, :description, :return_url, :capture_address,
                # :theme, :headline, :subheadline, :page_title, :request_preauthorization


  index do
    selectable_column
    id_column
    column :realm
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

  filter :realm
  filter :profile
  filter :name

  form do |f|
    f.inputs do
      f.input :realm, as: :select, collection: Realm.pluck(:name, :id)
      f.input :profile, as: :select, collection: Profile.pluck(:name, :id)
      f.input :campaign, as: :select, collection: Campaign.pluck(:name, :id)

      # f.input :kind, as: :select, collection: Embed.kinds.map { |key,name| [name, key] }
      f.input :name
      f.input :internal_name

      #todo: friendly edit of these fields
      # f.input :payment_types
      # f.input :mailing_list
      # f.input :recurrence
      # f.input :suggested_amounts
      # f.input :fee_allocations
      # f.input :capture_memo, as: :boolean
      # f.input :consider_this
      # f.input :amount
      # f.input :description
      # f.input :return_url
      # f.input :capture_address   # list of address type: mailing, billing, shipping.  if present, then capture specified full addresses for payor
      # f.input :theme
      # f.input :headline
      # f.input :subheadline
      # f.input :page_title   # html head title tag
      # f.input :request_preauthorization, as: :boolean

      f.input :data_json, as: :text

      # todo: integrate friendlier json editor
      # https://lorefnon.me/2015/03/02/dealing-with-json-fields-in-active-admin.html
      # f.input :data, as: :text, input_html: { class: 'jsoneditor-target' }

      f.input :disabled

    end
    f.actions
  end

end
