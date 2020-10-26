class CreateOffices < ActiveRecord::Migration[6.0]
  def change
    create_table :offices do |t|
      t.string :name
      t.string :sanitized_name
      t.string :department
      t.string :region
      t.float :latitude
      t.float :longitude
      t.string :ot1
      t.string :ot2

      t.timestamps
    end
  end
end
