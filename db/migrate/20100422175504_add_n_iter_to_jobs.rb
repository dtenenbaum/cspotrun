class AddNIterToJobs < ActiveRecord::Migration
  def self.up
    add_column :jobs, :n_iter, :integer
  end

  def self.down
    remove_column :jobs, :n_iter
  end
end
