class CreateInstances < ActiveRecord::Migration
  def self.up
    create_table :instances do |t|
      t.column :job_id, :integer
      t.column :sir_id, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :instances
  end
end
