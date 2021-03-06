#gonzalez

batch = []
#BB00059.350
#batch.push('HB1V0300062000000201902121323G902124968049747HCP/WCB00780218470006600014420190212     ***  BATCH TOTALS  ***')
#BB00041.289
#batch.push('HB1V0300041000000201902064541G902082102221039HCP/WCB00780218470001600003520190208     ***  BATCH TOTALS  ***')

#BI00255.215
#batch.push('HB1V0300312000000201809023191G809065746957498HCP/WCB00780360650002800000020180906')
#batch.push('HB1V0300312000000201809023191G809065749957501RMB    00780360650000100000020180906')
#batch.push('HB1V0300312000000201809023191                       00780360650002900006620180906     ***  BATCH TOTALS  ***')

# BC01302.770  corresponds to claim file HC015539.010
#batch.push('HB1V0301718000000201903145490G903159788597887HCP/WCB00780155390000100000420190315     ***  BATCH TOTALS  ***')

#BC00243.799
batch.push('HB1V0300266000000201903174811G915180457104612HCP/WCB00780231100004000008320190318     ***  BATCH TOTALS  ***')

def do_file(s)
abort "not a batch file" unless s[0,3] = 'HB1'

batch_num = s[6,5]	    
operator_num = s[11,6]
batch_credate = s[17,8]     # submit date
batch_seqno = s[25,4]       # this is id that links to claim file; seqno is assigned by me
micro_start = s[29,11]
micro_end = s[40,5]
micro_type = s[45,7]
group_no = s[52,4]
provider_no = s[56,6]
number_of_claims = s[62,5]
number_of_records = s[67,6]  # Records in H claim file
batch_process_date =s[73,8]
edit_msg = s[81,40]
reject_flag = s[39,1]

puts "batch_num #{batch_num}"
puts "operator_num #{operator_num}"
puts "batch_credate #{batch_credate}" 
puts "batch_seqno #{batch_seqno}" 
puts "micro_start #{micro_start}"
puts "micro_end #{micro_end}"
puts "micro_type #{micro_type}" 
puts "group_no #{group_no}"
puts "provider_no #{provider_no}"
puts "number_of_claims #{number_of_claims}"
puts "number_of_records #{number_of_records}"
puts "batch_process_date #{batch_process_date}"
puts "edit_msg #{edit_msg}"
puts "reject_flag: #{reject_flag}"
puts
end

batch.each do |str|
  do_file(str)
end


