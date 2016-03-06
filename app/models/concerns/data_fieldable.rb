# assumes a data JSON field exists
# encapsulates handling of dynamic attributes

module DataFieldable
  extend ActiveSupport::Concern


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