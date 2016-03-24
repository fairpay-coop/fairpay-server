class Campaign < ActiveRecord::Base
  include DataFieldable
  include UuidAssignable

  # create_table :campaigns do |t|
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
  #   t.timestamps null: false


  belongs_to :profile

  has_many :embeds

  has_many :offers

  after_initialize :assign_uuid


  def display_name
    name
  end

  def financial_pcnt
    if financial_goal
      (100 * financial_total / financial_goal).round
    else
      nil
    end
  end

  def available_offers
    offers.select(&:is_available)
  end

  def apply_contribution(transaction)
    new_financial_total = financial_total.to_f + transaction.base_amount
    new_supporter_total = supporter_total.to_i + 1  #todo: check for uniq contributors
    # save!  #todo: make sure this is transactionally safe
    self.update!(financial_total: new_financial_total, supporter_total: new_supporter_total)
  end

end
