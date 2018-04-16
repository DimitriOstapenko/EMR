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

ActiveRecord::Schema.define(version: 20180415190102) do

  create_table "billings", force: :cascade do |t|
    t.integer "pat_id"
    t.string "doc_code"
    t.date "visit_date"
    t.integer "visit_id"
    t.string "proc_code"
    t.integer "proc_units"
    t.float "fee"
    t.string "btype"
    t.string "diag_code"
    t.string "status"
    t.float "amt_paid"
    t.date "paid_date"
    t.float "write_off"
    t.string "submit_file"
    t.integer "submit_year"
    t.string "remit_file"
    t.integer "remit_year"
    t.string "mohref"
    t.string "bill_prov"
    t.string "submit_user"
    t.datetime "submit_ts"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "doc_id"
    t.index ["pat_id", "visit_date", "created_at"], name: "index_billings_on_pat_id_and_visit_date_and_created_at"
  end

  create_table "daily_charts", force: :cascade do |t|
    t.string "filename"
    t.date "date"
    t.integer "pages"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_daily_charts_on_date"
    t.index ["filename"], name: "index_daily_charts_on_filename"
  end

  create_table "diagnoses", force: :cascade do |t|
    t.string "code"
    t.string "descr"
    t.string "prob_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false
    t.index ["code"], name: "index_diagnoses_on_code"
  end

  create_table "doctors", force: :cascade do |t|
    t.string "lname"
    t.string "fname"
    t.integer "cpso_num"
    t.integer "billing_num"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "service"
    t.string "ph_type"
    t.string "district"
    t.boolean "bills"
    t.string "address"
    t.string "city"
    t.string "prov"
    t.string "postal"
    t.string "phone"
    t.string "mobile"
    t.string "licence_no"
    t.text "note"
    t.string "office"
    t.string "provider_no"
    t.string "group_no"
    t.string "specialty"
    t.string "email"
    t.string "doc_code"
    t.index ["provider_no"], name: "index_doctors_on_provider_no"
  end

  create_table "drugs", force: :cascade do |t|
    t.string "name"
    t.string "dnum"
    t.string "strength"
    t.string "dose"
    t.string "freq"
    t.string "amount"
    t.string "status"
    t.string "generic"
    t.string "igcodes"
    t.string "format"
    t.string "route"
    t.integer "dur_cnt"
    t.string "dur_unit"
    t.integer "refills"
    t.integer "cost"
    t.string "lu_code"
    t.string "pharmacy"
    t.string "aliases"
    t.string "dtype"
    t.boolean "odb"
    t.string "filename"
    t.text "notes"
    t.text "instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoices", force: :cascade do |t|
    t.string "pat_id"
    t.integer "billto"
    t.integer "visit_id"
    t.decimal "amount"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date"
  end

  create_table "patients", force: :cascade do |t|
    t.string "lname"
    t.string "fname"
    t.string "ohip_num"
    t.date "dob"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sex"
    t.date "last_visit_date"
    t.string "addr"
    t.string "city"
    t.string "postal"
    t.string "prov"
    t.string "country"
    t.string "ohip_ver"
    t.string "hin_prov"
    t.date "hin_expiry"
    t.string "pat_type"
    t.string "pharmacy"
    t.string "pharm_phone"
    t.text "notes"
    t.string "alt_contact_name"
    t.string "alt_contact_phone"
    t.string "email"
    t.string "chart_file"
    t.string "family_dr"
    t.string "mobile"
    t.string "lastmod_by"
    t.string "mname"
    t.date "entry_date"
    t.string "allergies"
    t.string "medications"
    t.index ["email"], name: "index_patients_on_email"
    t.index ["last_visit_date"], name: "index_patients_on_last_visit_date"
    t.index ["lname"], name: "index_patients_on_lname"
    t.index ["mobile"], name: "index_patients_on_mobile"
    t.index ["ohip_num"], name: "index_patients_on_ohip_num"
    t.index ["pat_type"], name: "index_patients_on_pat_type"
    t.index ["phone"], name: "index_patients_on_phone"
  end

  create_table "procedures", force: :cascade do |t|
    t.string "code"
    t.string "qcode"
    t.integer "ptype"
    t.string "descr"
    t.float "cost"
    t.integer "unit"
    t.boolean "fac_req"
    t.boolean "adm_req"
    t.boolean "diag_req"
    t.boolean "ref_req"
    t.integer "percent"
    t.date "eff_date"
    t.date "term_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false
    t.integer "prov_fee"
    t.integer "ass_fee"
    t.integer "spec_fee"
    t.integer "ana_fee"
    t.integer "non_ana_fee"
    t.index ["code"], name: "index_procedures_on_code", unique: true
  end

  create_table "providers", force: :cascade do |t|
    t.string "name"
    t.string "addr1"
    t.string "addr2"
    t.string "city"
    t.string "prov"
    t.string "country"
    t.string "postal"
    t.string "phone1"
    t.string "phone2"
    t.string "fax"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reports", force: :cascade do |t|
    t.string "name"
    t.integer "doc_id"
    t.integer "rtype"
    t.string "filespec"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "sdate"
    t.date "edate"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.boolean "admin"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "vaccines", force: :cascade do |t|
    t.string "name"
    t.string "target"
    t.string "route"
    t.string "dose"
    t.string "din"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

# Could not dump table "visits" because of following StandardError
#   Unknown type 'real' for column 'weight'

end
