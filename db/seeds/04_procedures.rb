# Seed proctors table with real data from CSV file
#
#require 'csv'
#csv_text = File.read('/Users/dmitri/rstuff/walkin/lib/seeds/procfile_data.csv')
csv_text = File.read(Rails.root.join('lib', 'seeds', 'procfile_data.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')

csv.each do |row|
#	 puts row.to_hash

  proc  = Procedure.new  code:  row['proc_code'],
  			 qcode: row['qcode'],
  			 ptype: row['proc_type'],
  			 descr: row['proc_desc'],
  			 cost: row['proc_cost'],
  			 unit: row['proc_unit'],
  			 fac_req: row['fac_req'],
  			 adm_req: row['adm_req'],
  			 diag_req: row['diag_req'],
			 ref_req: row['ref_req'],
  			 percent: row['percent'],
  			 eff_date: row['eff_date'],
  			 term_date: row['term_date']

  if proc.save
     puts "#{proc.id} : #{proc.code} saved"
  else
     puts 'Problem procedure: ', proc.code
     puts proc.errors.full_messages
  end

end

puts " #{Procedure.count} rows created in proctors table"

# HS: apply_hst,proc_code,qcode,proc_type,proc_desc,proc_cost,proc_unit,fac_req,adm_req,diag_req,percent,eff_date,term_date,ref_req
#  t.string "code"
#    t.string "qcode"
#    t.string "descr"
#    t.decimal "cost", precision: 8, scale: 2
#    t.decimal "unit", precision: 8, scale: 2
#    t.boolean "fac_req"
#    t.boolean "adm_req"
#    t.boolean "diag_req"
#    t.boolean "ref_req"
#    t.decimal "percent", precision: 8, scale: 2
#    t.date "eff_date"
#    t.date "term_date"
#    t.datetime "created_at", null: false
#    t.datetime "updated_at", null: false

