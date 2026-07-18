class AddUrduNameToTradingPartners < ActiveRecord::Migration[8.0]
  def change
    add_column :trading_partners, :urdu_name, :string, null: false
  end
end
