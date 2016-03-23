class Offer < ActiveRecord::Base
  include DataFieldable
  include UuidAssignable
  include ApplicationHelper

  # create_table :offers do |t|
  #   t.string :uuid, index: true
  #   t.string :internal_name, index: true  # may be used to resolve reference as an alternative to uuid
  #   t.string :name
  #   t.text   :summary
  #   t.text   :details
  #   t.references :profile, index: true, foreign_key: true   # entity providing the offer. may differ from campaign owner for abuntoo use case
  #   t.references :campaign, index: true, foreign_key: true  # primary campaign assocaited with this offer, may have soft references
  #   t.string :kind
  #   t.string :status
  #   t.json   :data
  #   t.timestamps null: false
  #   t.decimal :financial_value
  #   t.integer :limit
  #   t.integer :allocated
  #   t.date    :expiry_date
  #   t.integer :minimum_contribution
  #   # for subscriptions
  #   t.integer :contribution_interval_count  # usually 1
  #   t.string  :contribution_interval_units  # month, year


  belongs_to :profile
  belongs_to :campaign

  after_initialize :assign_uuid


  def display_name
    name
  end

  def limited
    limit.to_i > 0
  end

  def remaining
    if limited
      limit - allocated
    else
      nil
    end
  end

  def is_available
    !limited || allocated < limit
  end

  def availability
    if limited
      "#{remaining}/#{limit} avail"
    else
      'unlimited'
    end
  end

  def label
    result = "#{name} (#{availability})"
    result += ", min donation: $#{format_amount(minimum_contribution,0)}"  if minimum_contribution > 0
    result
  end

  # update persisted stats indicating an offer was taken
  def allocate
    allocated = 0  unless allocated
    allocated += 1
    # save!  #todo: make sure this is transactionally safe
    self.update!(allocated: allocated)
  end

end
