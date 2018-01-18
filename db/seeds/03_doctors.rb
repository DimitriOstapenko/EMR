# Seed doctors table with real data from CSV file
#
#require 'csv'
#csv_text = File.read('/Users/dmitri/rstuff/walkin/lib/seeds/doctors.csv')
csv_text = File.read(Rails.root.join('lib', 'seeds', 'doctors.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')

csv.each do |row|
#	 puts row.to_hash

  name = row['name']	
  name.gsub /DR\S?/, ''
  names = name.split(%r{,\s*})
  next unless names[0]
  names[1] = '' if names[1].nil?

  doc  = Doctor.new  lname:  names[0],
     		     fname:  names[1], 
		     cpso_num: row['cpso'],
     		     billing_num: '0',
		     service: row['scode'], 
		     ph_type: row['type'],
		     district: row['district'],
		     bills: row['bills'],
		     address: row['address1'],
		     city: row['city'],
		     prov: row['prov'],
		     postal: row['pc'],
		     phone: row['acode']+row['tele'],
		     mobile: row['altac'] + row['alttel'],
		     licence_no: row['licence_no'],
		     note: '',
		     office: row['office'],
		     provider_no: row['provider'],
		     group_no: row['group_no'],
		     specialty: row['specialty'],
		     email: row['email']

  if doc.save
     puts "#{doc.id} : #{doc.lname} saved"
  else
     puts 'Problem doc: '+ doc.lname
     puts doc.errors.full_messages
  end

end

puts " #{Doctor.count} rows created in doctors table"

#
#50.times do |n|
#        llname  = Faker::Name.last_name
#        fname  = Faker::Name.first_name
#        cpso = Faker::Number.number(5)
#        billing = Faker::Number.number(6)
#        lic = Faker::Number.number(8)
#        group_no = Faker::Number.number(4)
#        addr = Faker::Address.street_address
#        city = Faker::Address.city
#        phone  = Faker::PhoneNumber.phone_number
#        Doctor.create!(lname: llname,
#                       fname: fname,
#                       cpso_num: cpso,
#                       billing_num: billing,
#                       service: 'GENP',
#                       ph_type: 'GP',
#                       district: 'G',
#                       bills: true,
#                       address: addr,
#                       city: city,
#                       prov: 'ON',
#                       postal: 'L9G1G1',
#                       phone: phone,
#                       mobile: phone,
#                       licence_no: lic.to_s,
#                       note: 'empty',
#                       office: addr,
#                       provider_no: billing,
#                       group_no: group_no.to_s,
#                       specialty: '00',
#                       email: 'em@email.com'
#                      )
#end

