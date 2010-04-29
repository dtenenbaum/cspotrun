class AddUserSuppliedRdataToJob < ActiveRecord::Migration
  def self.up
    add_column :jobs, :user_supplied_rdata, :boolean
  end

  def self.down
    remove_column :jobs, :user_supplied_rdata
  end
end
