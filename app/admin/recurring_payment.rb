ActiveAdmin.register RecurringPayment do

# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if resource.something?
#   permitted
# end

  permit_params :status, :next_date, :master_transaction_id, :interval_count, :interval_units, :expires_date


  # create_table :recurring_payments do |t|
  #   t.string :uuid, index: true
  #   t.string :status
  #   t.references :master_transaction  - todo: is this needed?
  #   t.date :first_date
  #   t.date :expires_date
  #   t.date :next_date
  #   t.integer :interval_count
  #   t.string :interval_units
  #   t.json :data
  #   t.timestamps null: false


  index do
    selectable_column
    id_column
    column :uuid
    column :status
    column :next_date
    column :master_transaction
    column :interval_units
    actions
  end


  form do |f|
    f.inputs do
      f.input :uuid
      f.input :status, as: :select, collection: RecurringPayment::STATUS_VALUES
      f.input :next_date
      f.input :interval_count
      f.input :interval_units, as: :select, collection: RecurringPayment::INTERVAL_VALUES
      # f.input :interval_units
      f.input :expires_date
      f.input :master_transaction_id, as: :select, collection: Transaction.pluck(:uuid, :id)
      # f.input :data, as: :text
    end
    f.actions
  end


end
