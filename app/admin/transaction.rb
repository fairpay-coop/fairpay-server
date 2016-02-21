ActiveAdmin.register Transaction do


  permit_params :profile_id, :kind, :data


  index do
    selectable_column
    id_column
    column :payor
    column :payee
    column :base_amount
    column :payment_type
    column :status
    column :updated_at
    actions
  end


  form do |f|
    f.inputs do
      f.input :payor, as: :select, collection: Profile.pluck(:name, :id)
      f.input :payee, as: :select, collection: Profile.pluck(:name, :id)
      f.input :amount
      f.input :data, as: :text
    end
    f.actions
  end

end
