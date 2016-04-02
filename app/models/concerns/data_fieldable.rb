# assumes a data JSON field exists
# encapsulates handling of dynamic attributes

module DataFieldable
  extend ActiveSupport::Concern


  module ClassMethods

    #
    # define convenience methods for assigning and fetching the named attribute
    #
    # equivalent to:
    #
    # def foo
    #   get_translation('foo')
    # end
    #
    # def foo=(text)
    #   set_translation('foo', text)
    # end

    def attr_data_field(attribute) #todo: options, perhaps data type coercion?
      define_method(attribute) { get_data_field(attribute) }
      define_method("#{attribute}=") { |text| set_data_field(attribute, text) }
    end
  end


  def ensured_data
    self.data ||= {}
    self.data #.with_indifferent_access - this was breaking persistence
  end

  def indifferent_data
    ensured_data.with_indifferent_access
  end


  def get_data_field(name)
    ensured_data.with_indifferent_access[name]   # todo: make this more efficient, memoize the indifferent access hash?
  end

  def set_data_field(name, value)
    ensured_data[name.to_s] = value
  end

  def update_data_field(name, value)
    set_data_field(name, value)
    self.save
  end

  # need to alias for the active admin to be functional
  def data_json
    data&.to_json
  end

  def data_json=(text)
    self.data = JSON.parse(text)
    puts "assigned data: #{data}"
  end



end