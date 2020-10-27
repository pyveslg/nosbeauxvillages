class AddOtToVillage < ActiveRecord::Migration[6.0]
  def change
    add_column :villages, :ot, :json, default: {}
  end
end
