class AddDataToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :data, :json
  end
end
