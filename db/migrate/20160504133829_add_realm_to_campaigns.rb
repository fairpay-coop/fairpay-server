class AddRealmToCampaigns < ActiveRecord::Migration
  def change
    add_reference :campaigns, :realm, index: true, foreign_key: true
    default_realm = Realm.find_by(internal_name: 'default')
    Campaign.update_all(realm_id: default_realm.id)
  end
end
