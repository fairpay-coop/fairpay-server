class CreateEmbeds < ActiveRecord::Migration
  def change
    create_table :embeds do |t|
      t.string :uuid, index: true
      t.references :profile, index: true, foreign_key: true
      t.string :kind
      t.json :data

      t.timestamps null: false
    end
  end
end
