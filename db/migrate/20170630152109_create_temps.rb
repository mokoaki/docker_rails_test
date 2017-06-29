class CreateTemps < ActiveRecord::Migration[5.1]
  def change
    create_table :temps do |t|
      t.string :name

      t.timestamps
    end
  end
end
