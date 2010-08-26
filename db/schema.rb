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

ActiveRecord::Schema.define(:version => 20100628233854) do

  create_table "events", :force => true do |t|
    t.integer  "job_id"
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "instance_id"
    t.string   "public_ip"
  end

  create_table "instances", :force => true do |t|
    t.integer  "job_id"
    t.string   "sir_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.string   "public_ip"
  end

  create_table "jobs", :force => true do |t|
    t.string   "name"
    t.string   "instance_type"
    t.float    "price"
    t.string   "status"
    t.string   "email"
    t.string   "organism"
    t.string   "project"
    t.integer  "k_clust"
    t.text     "ratios_file"
    t.boolean  "is_test_run"
    t.string   "command"
    t.integer  "num_instances"
    t.string   "user_data_file"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "n_iter"
    t.boolean  "user_supplied_rdata"
    t.boolean  "has_preinit_script"
    t.string   "script_filename"
    t.boolean  "has_postproc_script"
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
