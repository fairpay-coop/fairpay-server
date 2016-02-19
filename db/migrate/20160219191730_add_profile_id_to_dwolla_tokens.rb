class AddProfileIdToDwollaTokens < ActiveRecord::Migration
  def change
    add_reference :dwolla_tokens, :profile, index: true, foreign_key: true

  end
end
