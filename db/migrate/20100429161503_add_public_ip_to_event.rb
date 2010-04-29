class AddPublicIpToEvent < ActiveRecord::Migration
  def self.up
    add_column :events, :public_ip, :string
  end

  def self.down
    remove_column :events, :public_ip
  end
end
