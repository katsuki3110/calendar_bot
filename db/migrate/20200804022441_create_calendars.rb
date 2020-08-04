class CreateCalendars < ActiveRecord::Migration[5.2]
  def change
    create_table :calendars do |t|
      t.string :user
      t.date :date
      t.string :content

      t.timestamps
    end
  end
end
