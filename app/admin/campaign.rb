ActiveAdmin.register Campaign do

  permit_params :uuid, :internal_name, :name, :summary, :details, :profile_id, :kind, :status, :data_json,
                :starting_date, :closing_date, :financial_goal, :financial_minimum, :financial_total,
                :financial_pledges, :supporter_goal, :supporter_minimum, :supporter_total, :supporter_pledges,
                :realm_id

  index do
    selectable_column
    id_column
    column :realm
    column :name
    column :profile
    column :financial_goal
    column :financial_total
    column :supporter_goal
    column :supporter_total
    column :updated_at
    actions
  end


  #   t.string :uuid, index: true
  #   t.string :internal_name, index: true  # may be used to resolve reference as an alternative to uuid
  #   t.string :name
  #   t.text :summary
  #   t.text :details
  #   t.references :profile, index: true, foreign_key: true
  #   t.string :kind
  #   t.string :status
  #   t.json :data
  #   t.date :starting_date
  #   t.date :closing_date
  #   #todo add currency support
  #   t.decimal :financial_goal
  #   t.decimal :financial_minimum  # implies that campaign has a tipping level
  #   t.decimal :financial_total    # total firm payments.  depending on campaign type, may be one time amounts, per month, or per year
  #   t.decimal :financial_pledges  # soft pledges. should this also include firm payments?
  #   t.integer :supporter_goal
  #   t.integer :supporter_minimum
  #   t.integer :supporter_total    # number of people who have made firm payments
  #   t.integer :supporter_pledges  # count of people who have made soft pledges

  form do |f|
    f.inputs do
      f.input :realm, as: :select, collection: Realm.pluck(:name, :id)

      f.input :profile, as: :select, collection: Profile.pluck(:name, :id)
      f.input :kind  #, as: :select, collection: Campaign.kinds.map { |key,name| [name, key] }
      f.input :name
      f.input :internal_name
      f.input :status
      f.input :summary
      f.input :details
      f.input :data_json, as: :text

      f.input :starting_date
      f.input :closing_date
      f.input :financial_goal
      f.input :financial_minimum  # implies that campaign has a tipping level
      f.input :financial_total    # total firm payments.  depending on campaign type, may be one time amounts, per month, or per year
      f.input :financial_pledges  # soft pledges. should this also include firm payments?
      f.input :supporter_goal
      f.input :supporter_minimum
      f.input :supporter_total    # number of people who have made firm payments
      f.input :supporter_pledges  # count of people who have made soft pledges
    end
    f.actions
  end

end
