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

  STATUS_VALUES = [:active, :complete, :cancelled]
  INTERVAL_VALUES = [:day, :week, :month, :year]


  def increment_next_date
    last_date = fetch_last_date || Date.today
    new_next = apply_interval(last_date)
    puts "setting next_date to: #{next_date}"
    update_data = {next_date: new_next}
    update_data[:status] = :complete  unless new_next
    update!(update_data)
  end

  def fetch_last_date
    transactions.last&.created_at
  end

  def apply_interval(date)
    interval = interval_count.send(interval_units)
    new_date = date + interval
    if expires_date && new_date > expires_date
      puts "recurring payment expired"
      new_date = nil
      # update!(status: :complete, )
    end
    new_date
  end

  def perform_payment
    ref_tran = master_transaction
    new_transaction = Transaction.create!(
        payee: ref_tran.payee,
        payor: ref_tran.payor,
        base_amount: ref_tran.base_amount,
        # payment_source: ref_tran.payment_source,
        payment_type: ref_tran.payment_type,
        recurring_payment: self,
        parent: ref_tran,
        status: :provisional,
    )
    new_transaction.perform_payment(use_payment_source: true)
    increment_next_date
  end

  def self.perform_all_pending
    all_pending.each(&:perform_payment)
  end

  def self.all_pending
    RecurringPayment.where("status = 'active' and next_date <= ?", Date.today)
  end

end
