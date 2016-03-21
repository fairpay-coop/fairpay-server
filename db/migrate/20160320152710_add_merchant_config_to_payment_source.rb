class AddMerchantConfigToPaymentSource < ActiveRecord::Migration
  def change
    add_reference :payment_sources, :merchant_config, index: true, foreign_key: true
    add_column :payment_sources, :source_key, :string, index: true

    PaymentSource.where(kind: :dwolla).update_all(source_key: ENV['DWOLLA_CLIENT_ID'])

  end
end
