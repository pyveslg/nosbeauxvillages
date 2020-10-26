class CreateGares < ActiveRecord::Migration[6.0]
  def change
    create_table :gares do |t|
      t.string :localty
      t.string :department
      t.string :zipcode
      t.string :cog
      t.float :latitude
      t.float :longitude
      t.string :place
      t.string :region_sncf
      t.string :region

      t.timestamps
    end
  end
end
