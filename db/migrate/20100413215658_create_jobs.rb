class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.column :name, :string
      t.column :instance_type, :string
      t.column :price, :float
      t.column :status, :string
      t.column :email, :string
      t.column :organism, :string
      t.column :project, :string
      t.column :k_clust, :integer
      t.column :ratios_file, :text
      t.column :is_test_run, :boolean
      t.column :command, :string
      t.column :num_instances, :integer
      t.column :user_data_file, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :jobs
  end
end
