ActiveAdmin.register Offer do

  permit_params :uuid, :internal_name, :name, :summary, :details, :profile_id, :campaign_id, :kind, :status, :data_json, :financial_value, :limit, :allocated, :expiry_date, :minimum_contribution, :contribution_interval_count, :contribution_interval_units


  index do
    selectable_column
    id_column
    column :uuid
    column :name
    column :profile
    column :campaign
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
      f.input :data_json, as: :text

      f.input :financial_value
      f.input :limit
      f.input :allocated
      f.input :expiry_date
      f.input :minimum_contribution
      f.input :contribution_interval_count #todo: select options
      f.input :contribution_interval_units

    end
    f.actions
  end

end
