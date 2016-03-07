class AddMiscNameFields < ActiveRecord::Migration
  def change
    add_column :embeds, :name, :string
    add_column :embeds, :internal_name, :string
    add_column :embeds, :disabled, :boolean, default: false, null: false

    add_column :merchant_configs, :name, :string
    add_column :merchant_configs, :internal_name, :string
    add_column :merchant_configs, :disabled, :boolean, default: false, null: false

    add_column :profiles, :first_name, :string
    add_column :profiles, :last_name, :string

    add_column :payment_sources, :name, :string
    # add_column :recurring_payments, :name, :string
    # add_column :transactions, :name, :string

  end
end
