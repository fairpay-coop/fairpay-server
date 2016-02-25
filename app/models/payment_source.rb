class PaymentSource < ActiveRecord::Base

  # create_table :payment_sources do |t|
  #   t.references :profile, index: true, foreign_key: true
  #   t.string :kind
  #   t.json :data
  #   t.timestamps null: false


  belongs_to :profile


  def ensured_data
    self.data ||= {}
    self.data #.with_indifferent_access - this was breaking persistence
  end

  def get_data_field(name)
    ensured_data.with_indifferent_access[name]
  end

  def set_data_field(name, value)
    ensured_data[name.to_s] = value
  end

  def update_data_field(name, value)
    set_data_field(name, value)
    self.save
  end

end
