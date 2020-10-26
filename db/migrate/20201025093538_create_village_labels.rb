class CreateVillageLabels < ActiveRecord::Migration[6.0]
  def change
    create_table :village_labels do |t|
      t.string :link
      t.references :village, null: false, foreign_key: true
      t.references :label, null: false, foreign_key: true

      t.timestamps
    end
  end
end
