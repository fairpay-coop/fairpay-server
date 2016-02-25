class AddDwollaTokenRefToPaymentSource < ActiveRecord::Migration
  def change
    # add_reference :profiles, :dwolla_token, foreign_key: true

    # do we even need this, or just a dwolla_account_id in the payment source map
    # add_reference :payment_sources, :dwolla_token, foreign_key: true

    remove_reference :dwolla_tokens, :profile, index: true, foreign_key: true

  end
end
