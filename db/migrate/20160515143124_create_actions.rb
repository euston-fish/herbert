class CreateActions < ActiveRecord::Migration
  def change
    create_table :actions do |t|
      t.datetime :timestamp
      t.text     :action
      t.text     :user_id
    end
  end
end
