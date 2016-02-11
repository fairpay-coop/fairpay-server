ActiveAdmin.register Binbase do

  permit_params :bin, :card_brand, :card_type, :card_category, :country_iso, :org_website, :org_phone, :binbase_org_id

  index do
    selectable_column
    id_column
    column :bin
    column :card_brand
    column :card_type
    column :card_category
    column :country_iso
    column :binbase_org
    column :updated_at
    actions
  end


  # form do |f|
  #   f.inputs do
  #     f.input :payor, as: :select, collection: Profile.pluck(:name, :id)
  #     f.input :payee, as: :select, collection: Profile.pluck(:name, :id)
  #     f.input :amount
  #     f.input :data, as: :text
  #   end
  #   f.actions
  # end


end
