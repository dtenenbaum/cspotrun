class AddInstanceIdToEvent < ActiveRecord::Migration
  def self.up
    add_column :events, :instance_id, :integer
  end

  def self.down
    remove_column :events, :instance_id
  end
end
