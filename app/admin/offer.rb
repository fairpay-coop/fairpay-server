ActiveAdmin.register Offer do

  permit_params :uuid, :internal_name, :name, :summary, :details, :profile_id, :campaign_id, :kind, :status,
                :financial_value, :limit, :allocated, :expiry_date, :minimum_contribution,
                :contribution_interval_count, :contribution_interval_units,
                :provided_by, :provider_website, :redeemable_in, :ships_to, :shipping_address_needed,
                :redemption_details
  #:data_json,


  index do
    selectable_column
    id_column
    column :uuid
    column :name
    column :profile
    column :campaign
    column :kind
    column :limit
    column :allocated
    column :status
    column :updated_at
    actions
  end


  form do |f|
    f.inputs do
      f.input :profile, as: :select, collection: Profile.pluck(:name, :id)
      f.input :campaign, as: :select, collection: Campaign.pluck(:name, :id)
      f.input :kind  #, as: :select, collection: Campaign.kinds.map { |key,name| [name, key] }
      f.input :name
      f.input :internal_name
      f.input :status
      f.input :summary
      f.input :details
      # f.input :data_json, as: :text

      f.input :financial_value
      f.input :limit
      f.input :allocated
      f.input :expiry_date
      f.input :minimum_contribution
      f.input :contribution_interval_count #todo: select options
      f.input :contribution_interval_units

      f.input :provided_by
      f.input :provider_website
      f.input :redeemable_in
      f.input :ships_to
      f.input :shipping_address_needed, as: :boolean
      f.input :redemption_details, as: :text

    end
    f.actions
  end

end
