class CreateRealms < ActiveRecord::Migration
  def change
    create_table :realms do |t|
      t.string :name
      t.string :internal_name
      t.timestamps null: false
    end
    default_realm = Realm.create(name: 'Default', internal_name: 'default')

    add_reference :users, :realm, index: true, foreign_key: true
    add_reference :profiles, :realm, index: true, foreign_key: true
    add_reference :embeds, :realm, index: true, foreign_key: true

    User.update_all(realm_id: default_realm.id)
    Profile.update_all(realm_id: default_realm.id)
    Embed.update_all(realm_id: default_realm.id)

  end
end
