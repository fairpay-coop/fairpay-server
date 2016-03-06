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

  end


end