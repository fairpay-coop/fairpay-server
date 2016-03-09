ActiveAdmin.register Transaction do


  permit_params :payor_id, :payee_id, :base_amount, :kind  # /, :data_json


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
    column :updated_at
    actions
  end


  form do |f|
    f.inputs do
      f.input :payor, as: :select, collection: Profile.pluck(:name, :id)
      f.input :payee, as: :select, collection: Profile.pluck(:name, :id)
      f.input :base_amount
      f.input :payment_type
      f.input :status
      f.input :recurrence
      # f.input :data_json, as: :text
    end
    f.actions
  end

end
