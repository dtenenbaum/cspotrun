class AddScriptFilename < ActiveRecord::Migration
  def self.up
    add_column :jobs, :script_filename, :string
  end

  def self.down
    remove_column :jobs, :script_filename
  end
end
