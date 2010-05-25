class AddPreInitScriptFlagToJob < ActiveRecord::Migration
  def self.up
    add_column :jobs, :has_preinit_script, :boolean
  end

  def self.down
    remove_column :jobs, :has_preinit_script
  end
end
