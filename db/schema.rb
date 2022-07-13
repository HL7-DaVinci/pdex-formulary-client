# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_07_10_181751) do

  create_table "client_connections", force: :cascade do |t|
    t.string "server_url"
    t.string "client_id"
    t.string "client_secret"
    t.string "scope"
    t.string "aud"
    t.string "redirect_url", default: "http://localhost:3000/login"
    t.index ["server_url"], name: "index_client_connections_on_server_url", unique: true
  end

end
