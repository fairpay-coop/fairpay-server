class Realm < ActiveRecord::Base

  # create_table :realms do |t|
  #   t.string :name
  #   t.string :internal_name
  #   t.timestamps null: false


  def self.default
    Realm.find_by_internal_name(:default)
  end

end
