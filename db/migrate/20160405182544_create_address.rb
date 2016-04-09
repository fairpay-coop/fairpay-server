class CreateAddress < ActiveRecord::Migration
  def change
    create_table :addresses do |t|

      t.string :uuid, index: true  # identifier used by api
      t.string :kind   # mailing, billing, shipping
      t.string :label  # potentially user supplied label for specific address
      t.references :profile, index: true, foreign_key: true, null: false   # owning profile
      t.references :organization, index: true     # optionally associated organization

      t.string :first_name
      t.string :last_name
      t.string :organization_name
      t.string :street_address
      t.string :extended_address
      t.string :locality      # city
      t.string :region        # state
      t.string :postal_code
      t.string :country_code  # 2 letter iso code

      t.json   :data          # not currently used
      t.timestamps null: false

    end

    add_foreign_key :addresses, :profiles, column: :organization_id

  end
end

