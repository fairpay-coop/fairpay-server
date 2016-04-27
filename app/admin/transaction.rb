ActiveAdmin.register Transaction do


  permit_params :payor_id, :payee_id, :base_amount, :kind, :fee_allocation, :allocated_fee, :paid_amount, :payment_type, :status, :recurrence, :offer_id, :data_json


  index do
    selectable_column
    id_column
    column :uuid
    column :payor
    column :payee
    column :base_amount
    column :payment_type
    column :status
    column :recurrence
    column :offer
    column :updated_at
    actions
  end


  form do |f|
    f.inputs do
      f.input :payor, as: :select, collection: Profile.pluck(:name, :id)
      f.input :payee, as: :select, collection: Profile.pluck(:name, :id)
      f.input :fee_allocation
      f.input :base_amount
      f.input :allocated_fee
      f.input :paid_amount
      f.input :payment_type
      f.input :status
      f.input :recurrence
      f.input :offer, as: :select, collection: Offer.pluck(:name, :id)
      f.input :data_json, as: :text
    end
    f.actions
  end

end
