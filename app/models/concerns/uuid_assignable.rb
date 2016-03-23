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

    # fetches instance by either uuid or internal name
    def resolve(identifier, required:true)
      #todo: be smart about existance of 'internal_name', for now assume not called unless exists
      result = by_uuid(identifier) || find_by_internal_name(identifier)
      raise "#{self.name} not found for identifier: #{identifier}"  if required && !result
      result
    end


  end


end