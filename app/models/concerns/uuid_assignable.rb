module UuidAssignable
  extend ActiveSupport::Concern


  # after_initialize :assign_uuid

  # todo? factor to ActiveRecord::Base
  def assign_uuid
    self.uuid ||= SecureRandom.urlsafe_base64(8)
  end


  module ClassMethods

    def by_uuid(uuid)
      self.find_by(uuid: uuid)
    end

    # fetches instance by either uuid or internal name.  if list provided just return first value
    def resolve(identifier_raw, required:true)
      return nil  if identifier_raw.blank? && !required
      identifier = identifier_raw.split(',').first  # parse out first value if comma separated
      #todo: be smart about existance of 'internal_name', for now assume not called unless exists
      result = by_uuid(identifier) || find_by_internal_name(identifier)
      raise "#{self.name} not found for identifier: #{identifier}"  if required && !result
      result
    end

    def resolve_list(identifier_raw)
      return []  if identifier_raw.blank?
      identifier_raw.split(',').map{|id| resolve(id, required:false)}.compact
    end

  end


end