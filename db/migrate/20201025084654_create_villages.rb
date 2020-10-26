class CreateVillages < ActiveRecord::Migration[6.0]
  def change
    create_table :villages do |t|
      t.string :place
      t.string :localty
      t.string :department
      t.string :region
      t.string :zipcode
      t.string :cog
      t.float :latitude
      t.float :longitude
      t.integer :population

      t.timestamps
    end
  end
end
