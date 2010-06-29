class AddPostprocFlagToJobs < ActiveRecord::Migration
  def self.up
    add_column :jobs, :has_postproc_script, :boolean
  end

  def self.down
    remove_column :jobs, :has_postproc_script
  end
end
