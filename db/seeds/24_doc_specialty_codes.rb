# Import Claim error codes into claim_errors table 
#
require_relative '../../config/environment'
require 'csv'

TABLE='specialty_codes'

source_file = Rails.root.join('lib', 'seeds','specialty_codes.csv')
abort "Source file does not exist." unless File.exists?(source_file)

puts "About to seed #{TABLE} from file #{source_file}"

SpecialtyCode.destroy_all

code = descr = ''
codes = 0
lines = File.readlines source_file
lines.each do |line|
  (code,descr) =  line.split(',').collect(&:strip)
  next unless code.present? && code.match(/^[[:digit:]]{2}$/)
  code_obj = SpecialtyCode.new(code: code, description: descr)
  if code_obj.save		         
	  puts "#{code} #{descr} saved"
	  codes += 1
  else
	  puts 'Problem line: ', code_obj.inspect
          puts code_obj.errors.full_messages
  end
end

puts "Imported #{codes} codes. Now #{SpecialtyCode.count} codes in a #{TABLE} table"
