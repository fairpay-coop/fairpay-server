class RecurringPayment < ActiveRecord::Base
  include UuidAssignable

  # create_table :recurring_payments do |t|
  #   t.string :uuid, index: true
  #   t.string :status
  #   t.references :master_transaction
  #   t.integer :interval_count
  #   t.string :interval_units
  #   t.date :expires_date
  #   t.date :next_date
  #   t.json :data
  #   t.timestamps null: false


  belongs_to :master_transaction, class_name: 'Transaction'
  has_many :transactions   #todo: confirm/guarantee .last behavior


  after_initialize :assign_uuid

  STATUS_VALUES = [:active, :cancelled]
  INTERVAL_VALUES = [:day, :week, :month, :year]


  def increment_next_date
    last_date = fetch_last_date || Date.today
    new_next = apply_interval(last_date)
    puts "setting next_date to: #{next_date}"
    update!(next_date: new_next)
  end

  def fetch_last_date
    transactions.last&.created_at
  end

  def apply_interval(date)
    interval = interval_count.send(interval_units)
    date + interval
  end

end
