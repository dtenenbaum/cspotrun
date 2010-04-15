class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.column :job_id, :integer
      t.column :text, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
