class AddPublicIpToInstance2 < ActiveRecord::Migration
  def self.up
    add_column :instances, :public_ip, :string
  end

  def self.down
    remove_column :instances, :public_ip
  end
end
