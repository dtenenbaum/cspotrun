# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100423204408) do

  create_table "events", :force => true do |t|
    t.integer  "job_id",      :limit => 11
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "instance_id", :limit => 11
  end

  create_table "instances", :force => true do |t|
    t.integer  "job_id",     :limit => 11
    t.string   "sir_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "jobs", :force => true do |t|
    t.string   "name"
    t.string   "instance_type"
    t.float    "price"
    t.string   "status"
    t.string   "email"
    t.string   "organism"
    t.string   "project"
    t.integer  "k_clust",        :limit => 11
    t.text     "ratios_file"
    t.boolean  "is_test_run"
    t.string   "command"
    t.integer  "num_instances",  :limit => 11
    t.string   "user_data_file"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "n_iter",         :limit => 11
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
