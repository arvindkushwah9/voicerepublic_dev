# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121113132505) do

  create_table "accounts", :force => true do |t|
    t.string   "timezone"
    t.string   "language_1"
    t.string   "language_2"
    t.string   "language_3"
    t.integer  "user_id"
    t.text     "about"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.string   "portrait_file_name"
    t.string   "portrait_content_type"
    t.integer  "portrait_file_size"
    t.datetime "portrait_updated_at"
    t.text     "prefs"
  end

  create_table "balance_accounts", :force => true do |t|
    t.string   "currency"
    t.integer  "balance_cents", :default => 0
    t.integer  "revenue_cents", :default => 0
    t.integer  "user_id"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  create_table "balance_check_in_orders", :force => true do |t|
    t.integer  "balance_account_id"
    t.boolean  "completed"
    t.datetime "completed_at"
    t.string   "currency"
    t.integer  "amount_cents"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "bookmarks", :force => true do |t|
    t.integer  "klu_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "category_translations", :force => true do |t|
    t.integer  "category_id"
    t.string   "locale"
    t.string   "name"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "category_translations", ["category_id"], :name => "index_category_translations_on_category_id"
  add_index "category_translations", ["locale"], :name => "index_category_translations_on_locale"

  create_table "comments", :force => true do |t|
    t.text     "content"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.integer  "user_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["commentable_type"], :name => "index_comments_on_commentable_type"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "conversations", :force => true do |t|
    t.integer  "user_1_id"
    t.integer  "user_2_id"
    t.integer  "offset_1"
    t.integer  "offset_2"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "conversations", ["user_1_id"], :name => "index_conversations_on_user_1_id"
  add_index "conversations", ["user_2_id"], :name => "index_conversations_on_user_2_id"

  create_table "credit_accounts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "prepaid_amount"
    t.integer  "revenue_amount"
    t.string   "currency"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "follows", :force => true do |t|
    t.integer  "follower_id"
    t.integer  "followed_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "klu_images", :force => true do |t|
    t.text     "description"
    t.integer  "klu_id"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "klus", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "available_at_times"
    t.integer  "user_id"
    t.boolean  "published",          :default => false
    t.integer  "category_id"
    t.string   "type"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "charge_type",        :default => "free"
    t.boolean  "uses_status",        :default => true
    t.string   "currency"
    t.integer  "charge_cents",       :default => 0
  end

  add_index "klus", ["charge_type"], :name => "index_klus_on_charge_type"

  create_table "messages", :force => true do |t|
    t.integer  "receiver_id"
    t.integer  "sender_id"
    t.text     "content"
    t.boolean  "receiver_read",    :default => false
    t.boolean  "sender_read",      :default => false
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.boolean  "sender_deleted",   :default => false
    t.boolean  "receiver_deleted", :default => false
    t.integer  "conversation_id"
  end

  add_index "messages", ["conversation_id"], :name => "index_messages_on_conversation_id"
  add_index "messages", ["receiver_id"], :name => "index_messages_on_receiver_id"
  add_index "messages", ["sender_id"], :name => "index_messages_on_sender_id"

  create_table "notification_bases", :force => true do |t|
    t.integer  "user_id"
    t.text     "content"
    t.integer  "klu_id"
    t.integer  "other_id"
    t.string   "url"
    t.string   "type"
    t.boolean  "read",             :default => false
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.integer  "video_session_id"
    t.string   "anon_id"
  end

  add_index "notification_bases", ["user_id"], :name => "index_notification_bases_on_user_id"

  create_table "participant_bases", :force => true do |t|
    t.string   "type"
    t.integer  "video_session_id"
    t.datetime "entered_timestamp"
    t.datetime "left_timestamp"
    t.string   "room_url"
    t.string   "video_session_role"
    t.string   "user_cookie_session_id"
    t.integer  "user_id"
    t.integer  "seconds_online",            :default => 0
    t.datetime "last_pay_tick_timestamp"
    t.integer  "pay_tick_counter",          :default => 0
    t.datetime "payment_started_timestamp"
    t.datetime "payment_stopped_timestamp"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
  end

  create_table "paypal_payments", :force => true do |t|
    t.text     "params"
    t.integer  "check_in_order_id"
    t.string   "status"
    t.integer  "amount_cents"
    t.string   "tact_id"
    t.string   "currency"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "ratings", :force => true do |t|
    t.integer  "rateable_id"
    t.integer  "user_id"
    t.string   "rateable_type"
    t.text     "content"
    t.integer  "score",         :default => 0
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "ratings", ["rateable_id"], :name => "index_ratings_on_rateable_id"
  add_index "ratings", ["rateable_type"], :name => "index_ratings_on_rateable_type"
  add_index "ratings", ["user_id"], :name => "index_ratings_on_user_id"

  create_table "roles", :force => true do |t|
    t.string "name"
  end

  create_table "status_updates", :force => true do |t|
    t.text     "content"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       :limit => 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "transfers", :force => true do |t|
    t.integer  "account_id"
    t.integer  "video_session_id"
    t.integer  "duration"
    t.integer  "transfer_charge_cents"
    t.string   "transfer_charge_currency"
    t.integer  "transfer_gross_cents"
    t.string   "transfer_gross_currency"
    t.integer  "video_session_charge_cents"
    t.string   "video_session_charge_currency"
    t.decimal  "exchange_rate",                 :precision => 10, :scale => 5
    t.string   "video_session_klu_name"
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
  end

  create_table "user_roles", :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  create_table "users", :force => true do |t|
    t.string   "firstname"
    t.string   "lastname"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "provider"
    t.string   "uid"
    t.text     "slug"
    t.datetime "last_request_at"
    t.string   "available"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["slug"], :name => "index_users_on_slug", :unique => true

  create_table "video_rooms", :force => true do |t|
    t.integer  "video_server_id"
    t.integer  "video_session_id"
    t.integer  "participant_count"
    t.string   "video_system_room_id"
    t.string   "name"
    t.string   "guest_password"
    t.string   "host_password"
    t.string   "welcome_msg"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "video_rooms", ["video_system_room_id"], :name => "index_video_rooms_on_video_system_room_id", :unique => true

  create_table "video_servers", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "salt"
    t.string   "version"
    t.boolean  "activated"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "video_session_bases", :force => true do |t|
    t.datetime "end_timestamp"
    t.datetime "begin_timestamp"
    t.string   "video_system_session_id"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.integer  "klu_id"
    t.string   "type"
  end

end
