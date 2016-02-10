class Embed < ActiveRecord::Base

  # create_table :embeds do |t|
  #   t.string :uuid, index: true
  #   t.references :profile, index: true, foreign_key: true
  #   t.string :kind
  #   t.json :data
  #   t.timestamps null: false


  belongs_to :profile

  after_initialize :assign_uuid


  def assign_uuid
    self.uuid ||= SecureRandom.urlsafe_base64(8)
  end

  def self.by_uuid(uuid)
    self.find_by(uuid: uuid)
  end

end
