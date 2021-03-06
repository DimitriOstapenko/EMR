# 2 Modules under My:
#
# 	- EDT: Functionality related to EDT claims submission
# 	- Forms: All pdf forms and docs
# 

module My

#--------------------------------
# EDT files related functionality
#--------------------------------
module EDT

# This is first record in every batch	  
# edt_id: id of new empty edt record; v: first visit in a batch
def heb_record( edt_id, v )
  cre_date = Date.today.strftime("%Y%m%d")
  batch_id = edt_id.to_s.rjust(4,'0')
  "HEBV03 #{cre_date}#{batch_id}#{' '*6}#{GROUP_NO}#{v.doctor.provider_no}00".ljust(79,' ') + "\r\n"
end

# Claim header record. One per claim
def heh_record(v, pat)
  if pat.pat_type == RMB_PATIENT
    "HEH#{' '*12}#{pat.dob.strftime("%Y%m%d")}#{v.id.to_s.rjust(8,'0')}RMBP".ljust(79,' ') +"\r\n"
  else
    "HEH#{pat.ohip_num}#{pat.ohip_ver}#{pat.dob.strftime("%Y%m%d")}#{v.id.to_s.rjust(8,'0')}HCPP".ljust(79,' ') +"\r\n"
  end
end

# HCP claim record
def het_record(v, s)
  "HET#{s[:pcode]}  #{(s[:fee]*s[:units]*100).to_i.to_s.rjust(6,'0')}#{s[:units].to_s.rjust(2,'0')}#{v.date_str}#{v.diag_code.to_i.to_s.rjust(3,'0')}".ljust(79,' ') + "\r\n"
end

# RMB claim record
def her_record(pat)
  "HER#{pat.ohip_num.ljust(12,' ')}#{pat.lname[0,9].ljust(9,' ')}#{pat.fname[0,5].ljust(5,' ')}#{DIGSEXES[pat.sex]}#{pat.hin_prov}".ljust(79,' ') + "\r\n"
end

# Totals. Final record in a batch
def hee_record( heh_count, her_count, het_count )
  "HEE#{heh_count.to_s.rjust(4,'0')}#{her_count.to_s.rjust(4,'0')}#{het_count.to_s.rjust(5,'0')}".ljust(79,' ') + "\r\n"
end

# h-records: 1/claim
# t-records: 1/any svs
# r-records: 1/rmb
# Generate claim file content
  def generate_claim_for_doc( edt_id, filename, visits )
      h_count = t_count = r_count = ttl_fee = 0; body = ''
      body << heb_record(edt_id, visits.first) 
      visits.all.each do |v| 
        pat = Patient.find(v.patient_id)
	ttl_fee += v.total_insured_fees
	if v.hcp_services? 
          body << heh_record(v,pat) 
	  h_count += 1
	  v.update_attribute(:status, BILLED) 
	  v.update_attribute(:export_file, filename) 
	  v.update_attribute(:billing_ref, v.id.to_s.rjust(8,'0')) 
	  if v.bil_type == RMB_BILLING  		# only 1 RMB claim supported per visit right now	
	    body << her_record(pat)
	    r_count += 1
	  end
	end
        v.services.each do |svc|
          next unless hcp_procedure?(svc[:pcode])
          body << het_record(v, svc)
          t_count += 1
        end
      end
      body << hee_record(h_count, r_count, t_count)
      return [body, h_count, t_count, ttl_fee]
  end

# Date of the last visit that was paid for by OHIP
  def last_paid_visit_date
    v = Visit.where(status: PAID).where("billing_ref is not null").order(:entry_ts).limit(1)
    return v[0].entry_ts.to_date rescue nil 
  end

end # EDT module

#-------------------------------------------      
# All Pdf forms/documents are generated here  
#-------------------------------------------
  module Forms

    require 'prawn'
    require 'prawn/table'
    require "prawn/measurement_extensions"

    CLINICINFO = "<b>Clinic:</b> 

                 #{CLINIC_NAME} 
                 #{CLINIC_ADDR} 
		 
                 Phone: #{CLINIC_PHONE}
		 Fax:   #{CLINIC_FAX}".freeze

# Generate visit form in PDF, return pdf object
  def build_visit_form ( pat, visit )
#          							top   right bottom left									
    pdf = Prawn::Document.new( :page_size => "LETTER", margin: [10.mm,10.mm,10.mm,10.mm])

    pdf.font "Courier"
    pdf.font_size 12
    pdf.stroke_rectangle [0,260.mm], 200.mm,260.mm

    patinfo = "<b>Patient</b>:
               <b>#{pat.full_name}</b> (#{pat.sex})
               #{pat.addr}
               #{pat.city}, #{pat.prov} #{pat.postal}

               <b>Phone: #{pat.phonestr} </b>File: #{pat.id}

               <b>DOB</b>: #{pat.dob} <b>Age</b>: #{pat.age_str} 
               <b>HCN</b>: #{pat.ohip_num} #{pat.ohip_ver} (#{pat.hin_prov})"

    visitinfo="<b>Provider</b>:
	      Dr. #{visit.doctor.lname}
              Family Doctor: #{pat.family_dr} 

              Date: <b>#{visit.entry_ts.strftime("%d-%b-%Y")}</b>
              Time: #{visit.entry_ts.strftime("%H:%M")}

              Visit Type: Walk In
              Visit Ref#: #{visit.id}"


    pdf.stroke do
                pdf.line_width=1
                pdf.horizontal_line 0,200.mm, :at => 215.mm     # Provider
                pdf.horizontal_line 0,200.mm, :at => 193.mm     # Meds
                pdf.horizontal_line 0,200.mm, :at => 183.mm     # Allergies
                pdf.horizontal_line 0,200.mm, :at => 163.mm     # Reason
                pdf.horizontal_line 0,200.mm, :at => 153.mm     # Vitals 
                pdf.vertical_line 215.mm,260.mm, :at => 100.mm  
                pdf.horizontal_line 32.mm,195.mm, :at => 25.mm  # Diag
                pdf.horizontal_line 32.mm,195.mm, :at => 15.mm  # Signature
              end

# Provider Info box    
    pdf.text_box visitinfo, :at => [5.mm,257.mm],
         :width => 100.mm,
         :height => 45.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 9,
         :inline_format => true

# Patient Info box         
    pdf.text_box patinfo, :at => [105.mm,257.mm],
         :width => 100.mm,
         :height => 45.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 9,
         :inline_format => true

# Medications box
    meds = (pat.med_count >0) ? pat.med_list.join(';  ') : pat.meds
    medinfo = "<b>Medications</b>: #{meds}"
    pdf.text_box medinfo, :at => [5.mm,212.mm],
         :width => 195.mm,
         :height => 23.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 9,
         :inline_format => true

    allergies = pat.allergies[0,65] rescue ''
    pdf.draw_text "Allergies: ", :at => [5.mm,185.mm], style: :bold
    pdf.draw_text allergies, :at => [35.mm,185.mm]
    
    reason = visit.reason[0,1000] rescue ''
    pdf.draw_text "Reason:", at: [5.mm,175.mm], style: :bold
    pdf.text_box reason, at: [26.mm,178.mm],
	 :width => 170.mm,
         :height => 15.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 9,
         :inline_format => true

    pdf.draw_text 'Vitals:', at: [5.mm,155.mm], style: :bold
    pdf.draw_text "T: #{visit.temp}", at: [35.mm,155.mm]
    pdf.draw_text "BP: #{visit.bp}", at: [69.mm,155.mm]
    pdf.draw_text "WT: #{visit.weight}", at: [118.mm,155.mm]
    pdf.draw_text "HR: #{visit.pulse}", at: [160.mm,155.mm]

    pdf.draw_text "Notes:", at: [5.mm,148.mm], style: :bold
    if !visit.notes.nil?
      pdf.text_box visit.notes, :at => [5.mm,145.mm],
         :width => 195.mm,
         :height => 110.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 9,
         :inline_format => true
    end

    pdf.draw_text "Diagnosis", at: [5.mm,25.mm]
    pdf.draw_text 'Signature:', at: [5.mm,15.mm]

    pdf.draw_text CLINIC_NAME, at: [5.mm,5.mm], style: :bold
    pdf.draw_text "#{CLINIC_ADDR} t:#{CLINIC_PHONE} f:#{CLINIC_FAX}", at: [5.mm,1.mm], size: 9 #, style: [:bold,:italic] 

    return pdf
  end # build_visit_form

# This PDF receipt is generated for 3RD party services only; 1 3RD party service per visit (1st)
  def build_visit_receipt ( pat, visit )

    pdf = Prawn::Document.new( :page_size => "LETTER", margin: [10.mm,10.mm,10.mm,10.mm])
    pdf.font "Courier"
    pdf.font_size 10
    pdf.stroke_rectangle [0,240.mm], 200.mm,240.mm

    if  !visit.cash?
      pdf.text "This visit does not have 3rd party service", size: 16, :align => :center
      return pdf 
    end

    today  = Date.today.strftime "%B %d, %Y"
    pdf.font "Courier"
    pdf.text 'Receipt for Professional Services', size: 16, :align => :center
    pdf.text 'Dr.' + visit.doctor.full_name,  size: 16, :align => :center

    patinfo = "<b>Patient:</b> 
    
               #{pat.full_name} (#{pat.sex})
               #{pat.addr}
               #{pat.city}, #{pat.prov} #{pat.postal}
               Born: #{pat.dob} 
               HCN: #{pat.ohip_num} #{pat.ohip_ver} (#{pat.hin_prov})
               File: #{pat.id}"
     serv_arr = []	       
     visit.services.each do |svc|
	next unless svc[:btype] == CASH_BILLING
        str = Date.today.to_s.ljust(85)
	str[15] = svc[:pcode]    
	str[30] = svc[:units].to_s rescue '1'
	str[40] = "$#{svc[:fee]}"      
	str[52] = "$#{svc[:fee]}"       
	str[65] = '$0.00'   
	serv_arr.push(str)
    end
                   
#                             1         2         3         4         5         6         7
#                    123456789012345678901234567890123456789012345678901234567890123456789012345

    serviceinfo = "<b> Service details </b>:  

                     Date           Descr         Qty       Charges     Payments     Balance   
   		     #{serv_arr.join("")}
    		     Total: #{sprintf('$%.2f',visit.total_cash)}"

# Clinic address box
    pdf.text_box CLINICINFO, :at => [5.mm,237.mm],
         :width => 95.mm,
         :height => 45.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 9,
         :inline_format => true

# Patient Info box
    pdf.text_box patinfo, :at => [105.mm,237.mm],
         :width => 100.mm,
         :height => 45.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 9,
         :inline_format => true

# Service description box:
    pdf.text_box serviceinfo, :at => [5.mm,192.mm],
         :width => 200.mm,
         :height => 45.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 9,
         :inline_format => true

#    descr = visit.reason.blank? ? visit.proc_descr : visit.reason[0,90]
#    pdf.draw_text descr, at: [5.mm, 162.mm]
    pdf.draw_text "Notes: #{visit.notes[0,68]}", :at => [5.mm,130.mm]

    pdf.stroke do
                pdf.line_width=1
                pdf.horizontal_line 0,200.mm, :at => 195.mm
                pdf.horizontal_line 0,200.mm, :at => 140.mm
                pdf.horizontal_line 0,200.mm, :at => 126.mm
                pdf.vertical_line 195.mm,240.mm, :at => 100.mm
              end

    return pdf
  end # build_receipt

# Generate patient's Lab label
  def build_label ( pat )
    @label = label_string ( pat )
    pdf = Prawn::Document.new(page_size: [90.mm, 29.mm], page_layout: :portrait, margin: [0.mm,2.mm,1.mm,1.mm])
    pdf.font "Helvetica", size: 10 
    pdf.text_box @label, :at => [2.mm,26.mm],
         :width => 80.mm,
         :height => 26.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 9,
	 :leading => 0,  # line spacing
         :inline_format => true

    return pdf
  end
 
# Generate patient's Address label
  def build_address_label ( pat )
    @label = addr_label_string ( pat )
    pdf = Prawn::Document.new(page_size: [90.mm, 29.mm], page_layout: :portrait, margin: [0.mm,2.mm,1.mm,1.mm])
    pdf.font "Helvetica", size: 10 
    pdf.text_box @label, :at => [2.mm,24.mm],
         :width => 85.mm,
         :height => 28.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 8,
	 :leading => 0,  # line spacing
         :inline_format => true

    return pdf
  end
  
# Build prescription pdf for given visit  
  def build_prescription ( pr )

    pat = pr.patient
    doc = pr.doctor
    visit = pr.visit

    if pat.blank?
      pdf.text "Patient not found in DB", size: 14, :align => :center
      return pdf
    end

    pdf = Prawn::Document.new( :page_size => "LETTER", margin: [10.mm,10.mm,10.mm,20.mm])
    pdf.font "Helvetica"
    pdf.font_size 14

    pdf.text CLINIC_NAME,  style: :bold, align: :center, size: 16
    pdf.text CLINIC_ADDR, align: :center 
    pdf.text "t: #{CLINIC_PHONE} f: #{CLINIC_FAX}",  align: :center
    
    pdf.move_down 10.mm

    pdf.text "For #{pat.full_name}"
    pdf.text "Address:  #{pat.addr} #{pat.city}, #{pat.prov} #{pat.postal}"
    pdf.text "HCN: #{pat.ohip_num} #{pat.ohip_ver} (#{pat.hin_prov})"

    pdf.move_down 10.mm
    pdf.text "Medications:", style: :bold
    pdf.move_down 5.mm
    pr.med_list.each_with_index do |med,i|
	    qty = "Qty: #{pr.aqty[i]}" if !pr.aqty[i].blank?
	    dur = "Dur: #{pr.aduration[i]}" if !pr.aduration[i].blank?
	    rep = "Rep: #{pr.arepeats[i]}" if !pr.arepeats[i].blank?
	    pdf.text "#{i+1} : #{med.name} #{med.strength} #{med.route} (#{med.dose} #{med.format}) #{med.freq} #{qty} #{dur} #{rep}"
    	    pdf.move_down 5.mm
    end

    pdf.move_down 20.mm
    pdf.text pr.date.strftime "%B %d, %Y"
    pdf.text "Dr. #{pr.doctor.lname}"
    pdf.text "BSc. MD. CCFP"
    pdf.text "PHY. # #{doc.provider_no} CPSO #{doc.cpso_num}"

    return pdf
  end

# Build invoice for given patient  
  def build_invoice ( inv )

    pat = Patient.find(inv.patient_id)
    if  pat.blank?
      pdf.text "Patient not found in DB. Please create patient first", size: 16, :align => :center
      return pdf
    end

    pdf = Prawn::Document.new( :page_size => "LETTER", margin: [10.mm,10.mm,10.mm,10.mm])
    pdf.font "Courier"
    pdf.font_size 10

    provider = Provider.find ( inv.billto )
    if provider.blank?
       pdf.text "Provider with id of #{inv.billto} does not exist in DB", size: 16, :align => :center
       return pdf
    end

    today  = Date.today.strftime "%B %d, %Y"
    servstr = Date.today.to_s.ljust(85)
    servstr[15] = 'Invoice'   
    servstr[30] = '1'
    servstr[40] = "$#{inv.amount}"      
                  
    inv_no = inv.id.to_s.rjust(3, "0")
    serviceinfo = "<b> Service details </b>:

                   Date           Code         Qty       Charges     Payments     Balance   
                  #{servstr} 
                  "
    pdf.stroke_rectangle [0,240.mm], 200.mm,113.mm
    pdf.text 'Invoice for Professional Services', size: 14, :align => :center
    
    pdf.text CLINIC_NAME, align: :center
    if inv.doctor.present?
       pdf.text "Dr. #{inv.doctor.full_name}",  size: 12, :align => :center
    end   
    pdf.text CLINIC_ADDR, align: :center

    pdf.draw_text "Invoice: #{inv_no}", at: [172.mm,243.mm], style: :bold
    if inv.doctor.present?
      pdf.draw_text "NOTES: Please make payable to Dr. #{inv.doctor.full_name}", at: [5.mm,132.mm], style: :italic
    else
      pdf.draw_text "NOTES: Please make payable to #{CLINIC_NAME}", at: [5.mm,132.mm], style: :italic
    end

    pdf.stroke do
	    pdf.line_width=0.2.mm
                pdf.horizontal_line 0,200.mm, :at => 195.mm
                pdf.horizontal_line 0,200.mm, :at => 140.mm
                pdf.horizontal_line 0,200.mm, :at => 35.mm
                pdf.vertical_line 195.mm,240.mm, :at => 120.mm
              end

    patinfo = "<b>Patient:</b> 
    
               #{pat.full_name} (#{pat.sex})
               #{pat.addr}
               #{pat.city}, #{pat.prov} #{pat.postal}
	       
               Born: #{pat.dob} 
               File: #{pat.id}"
    invoiceto = "<b>Invoice To</b>: #{provider.name}
 	        #{provider.addr1}	
 	        #{provider.addr2}	
                #{provider.city}, #{provider.prov} #{provider.postal}
     		  
     		 Date: #{today} "

    pdf.text_box patinfo, :at => [122.mm,237.mm],
         :width => 80.mm,
         :height => 45.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 9,
         :inline_format => true

    pdf.text_box invoiceto, :at => [5.mm,237.mm],
         :width => 120.mm,
         :height => 45.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 9,
         :inline_format => true	

    pdf.text_box serviceinfo, :at => [5.mm,192.mm],
         :width => 190.mm,
         :height => 50.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 9,
         :inline_format => true
    
    pdf.draw_text inv.notes[0,85], at: [5.mm, 162.mm]

# Tear-off footer     
    pdf.draw_text 'Submit this portion with your payment', at: [60.mm, 30.mm], style: :bold

    pdf.draw_text "Date: #{today}", at: [2.mm, 25.mm]
    pdf.draw_text "Patient: #{pat.full_name}", at: [2.mm, 18.mm]
    pdf.draw_text "Billed To: #{provider.name}", at: [2.mm, 11.mm]
    
    pdf.draw_text "Invoice: #{inv_no}", at: [140.mm, 25.mm]
    pdf.draw_text "Amount Billed: $#{inv.amount}", at: [140.mm, 18.mm]
    pdf.draw_text "Amount Paid: $", at: [140.mm, 11.mm]
    pdf.stroke { pdf.horizontal_line 170.mm,195.mm, :at => 11.mm }

#    pdf.draw_text "Please make cheque payable to: #{CLINIC_NAME}", at: [25.mm, 1.mm], style: :italic

    return pdf

  end # build_invoice

# Letter from Patient/Clinic  
  def build_letter (letter)
#          							top   right bottom left									
    pdf = Prawn::Document.new( :page_size => "LETTER", margin: [10.mm,10.mm,10.mm, 20.mm])
    pdf.font "Helvetica"
    pdf.font_size 10
    
    pdf.text CLINIC_NAME, align: :center, size: 14  #, style: :bold, size: 14
    pdf.text CLINIC_ADDR, align: :center
    pdf.text 'Tel: '+CLINIC_PHONE + ' Fax: ' + CLINIC_FAX, align: :center
    pdf.move_down 20.mm

    datestr = letter.date.strftime("%B %d, %Y") rescue ''

    pdf.text_box "#{datestr} \n#{letter.to} \n#{letter.address_to}", :at => [0,230.mm],
         :width => 60.mm,
         :height => 50.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 10,
         :inline_format => true
    
    pdf.move_down 30.mm
    pdf.text "RE: #{letter.patient.full_name} #{letter.patient.age_str}.o #{letter.patient.full_sex}"

    pdf.move_down 15.mm
    pdf.text letter.body, align: :left

    pdf.move_down 20.mm
    pdf.text "Sincerely,    #{letter.from}"

    return pdf
  end

# Generate specialist referral form
  def build_referral ( ref )

    pat = ref.patient	  
    doc = ref.doctor
    to_doc = ref.to_doctor
    meds = pat.meds   # concatenated string of all meds
    algies = pat.allergies
    datestr = ref.date.strftime("%B %d, %Y") rescue ''
    to_contact_info = "#{ref.address_to} \n P: #{ref.to_phone} F: #{ref.to_fax} "

    pdf = Prawn::Document.new( :page_size => "LETTER", margin: [10.mm,10.mm,10.mm,15.mm])
    pdf.font "Helvetica"
    pdf.font_size 11

    pdf.text "REFERRAL FORM ", align: :center, size: 12, style: :bold
    pdf.text CLINIC_NAME, align: :center, size: 12
    pdf.text CLINIC_ADDR, align: :center, size: 12
    pdf.text 'Tel: '+CLINIC_PHONE + ' Fax: ' + CLINIC_FAX, align: :center

    pdf.text_box "#{datestr} \n Dr. #{to_doc.lname} \n#{to_contact_info}", :at => [0,230.mm],
         :width => 60.mm,
         :height => 50.mm,
         :overflow => :shrink_to_fit,
         :min_font_size => 10,
         :inline_format => true

    pdf.stroke do
            pdf.line_width=0.2.mm
                pdf.horizontal_line 0,195.mm, :at => 200.mm
                pdf.horizontal_line 0,195.mm, :at => 150.mm
                pdf.vertical_line 150.mm,200.mm, :at => 100.mm
              end

    pdf.draw_text "Re: Patient:", at: [2.mm, 194.mm], style: :bold
    pdf.draw_text "Name:", at: [2.mm, 188.mm]
    pdf.draw_text "#{pat.full_name}, #{pat.age_str}.o #{pat.sex}", at: [16.mm, 188.mm]
    pdf.draw_text "Address:", at: [2.mm, 182.mm]
    pdf.draw_text "#{pat.addr}", at: [22.mm, 182.mm]
    pdf.draw_text "#{pat.city}, #{pat.prov} #{pat.postal}", at: [22.mm, 177.mm]
    pdf.draw_text "Telephone:", at: [2.mm, 168.mm]
    pdf.draw_text "#{pat.phonestr}", at: [25.mm, 168.mm]
    pdf.draw_text "DOB:", at: [2.mm, 161.mm]
    pdf.draw_text "#{pat.dob}", at: [12.mm, 161.mm]
    pdf.draw_text "HC#:", at: [2.mm, 155.mm]
    pdf.draw_text "#{pat.ohip_num} #{pat.ohip_ver}", at: [12.mm, 155.mm]
    pdf.draw_text "File#:", at: [55.mm, 155.mm]
    pdf.draw_text "#{pat.id}", at: [75.mm, 155.mm]
    
    pdf.draw_text "Referring Doctor:", at: [102.mm, 194.mm], style: :bold
    pdf.draw_text "Name:", at: [102.mm, 182.mm]
    pdf.draw_text " Dr. #{doc.lname}", at: [128.mm, 182.mm]
    pdf.draw_text "Billing No:", at: [102.mm, 174.mm]
    pdf.draw_text "#{doc.provider_no}", at: [128.mm, 174.mm]
    pdf.draw_text "Date:", at: [102.mm, 165.mm]
    pdf.draw_text Date.today, at: [128.mm, 165.mm]
    pdf.draw_text "Signature:", at: [102.mm, 156.mm]

    pdf.move_down 110.mm
    pdf.draw_text "Reason for Referral:", at: [0, 133.mm], style: :bold
    pdf.move_down 3.mm
    pdf.text ref.reason, align: :justify
    pdf.move_down 5.mm
    pdf.text "Medications:", style: :bold 
    pdf.move_down 3.mm
    pdf.text meds, align: :justify
    pdf.move_down 3.mm
    pdf.text "Allergies:", style: :bold
    pdf.move_down 3.mm
    pdf.text algies,  align: :justify
    
    pdf.move_down 10.mm
    pdf.text "Thank you for seeing this patient!", size: 12, style: :bold
    pdf.move_down 10.mm
    pdf.text "<b>Confirmed Appointment Date:</b> #{ref.app_date}", inline_format: true

    return pdf
 
  end

# Generate doctor's submitted claims billing report
  def build_sc_report( report, visits )
    @doc = Doctor.find(report.doc_id)
    sdate = report.sdate.strftime("%d %b %Y")
    edate = report.edate.strftime("%d %b %Y")
    date_range = report.timeframe == DAILY_REPORT ? sdate : "#{sdate} - #{edate}" 
    pdf = Prawn::Document.new( :page_size => "LETTER", margin: [10.mm,10.mm,20.mm,10.mm])

    pdf.text "#{CLINIC_NAME} #{CLINIC_ADDR} #{CLINIC_PHONE} #{CLINIC_FAX}", align: :center, size: 8
    pdf.move_down 5.mm
    pdf.text "#{REPORT_TFRAMES.invert[report.timeframe]} Billing Report For Dr. #{@doc.lname}, Prov# #{@doc.provider_no} Group# #{GROUP_NO}", align: :center, size: 12, style: :bold
    pdf.text "For services performed:  #{date_range}", align: :center, size: 12, style: :bold
    pdf.text "(Sorted by visit time, last to first)", align: :center, size: 10
    pdf.move_down 5.mm

    pdf.font "Courier"
    pdf.font_size 8
    @totals = {}
    @servcounts = {}
    @total_hcp_claims = 0
    (1..7).map{|key| @totals[key] = 0}
    (1..7).map{|key| @servcounts[key] = 0}

    rows =  [[ "Serv Date", "Patient", "OHIP#", "DOB", "Serv.", "Typ", "Fee", "Diag", "Status", "Acct#"]]
    visits.all.each do |v|
#pat = v.pat  # Patient.find(v.patient_id)
      next unless v.fee > 0
      next if v.bil_type < 1
      @total_hcp_claims += 1 if v.hcp_services?
      status = v.billing_ref.present? ? v.billing_ref : v.status_str
      rows += [[ v.entry_ts.strftime("%d/%m/%Y"), v.pat.full_name[0..19], v.pat.ohip_num_full, v.pat.dob.strftime("%d/%m/%Y"), v.proc_code[0..4], v.bil_type_str, v.fee, v.diag_scode, status, v.id ]]
      @totals[v.bil_type] += v.fee if v.bil_type.present?
      @servcounts[v.bil_type] += 1 if v.bil_type.present?
      serv = v.services
      serv.shift
      serv.each do |s|
        rows += [[ '','','', '', s[:pcode], BILLING_TYPES.invert[s[:btype]].to_s, s[:fee], v.diag_scode, v.billing_ref, v.pat.id ]]
	@totals[s[:btype]] += s[:fee] if s[:btype]
        @servcounts[s[:btype]] += 1 if s[:btype]
      end
    end

      pdf.table rows do |t|
        t.cells.border_width = 0 
	t.column_widths = [22.mm, 38.mm, 28.mm, 22.mm, 15.mm, 8.mm, 12.mm, 10.mm, 22.mm, 12.mm  ]
        t.header = true 
        t.row(0).font_style = :bold
        t.position = 5.mm
	t.cells.padding = 3
	t.cells.style do |c|
		c.background_color = c.row.odd? ? 'EEEEEE' : 'FFFFFF'
         end
      end
      
      pdf.move_down 10.mm
      pdf.span(190.mm, :position => :center) do
        pdf.text "Total Claims: #{@total_hcp_claims}", size: 9
        totals = [[ '', "HCP", "RMB", "INVOICE", "CASH", "WCB", "PRV", 'IFH', "Total" ]]
        @fees = @totals.values
        @fees.push(@fees.sum)
        totals += [ @fees.map{|e| sprintf("$%-8.2f",e)}.unshift('Fees') ]
        @services = @servcounts.values
        @services.push(@services.sum)
        totals += [ @services.unshift('Services') ]
        pdf.table totals do |t|
          t.cells.border_width = 1
	  t.column_widths = 20.mm 
          t.header = true
          t.row(0).font_style = :bold
        end
      end
    return pdf
  end

# Generate paid claims report  
  def build_pc_report ( report, claims)
    @doc = report.doctor
    sdate = report.sdate.strftime("%d %b %Y")
    edate = report.edate.strftime("%d %b %Y")
    date_range = "#{sdate} - #{edate}"	  
    date_range = sdate if report.timeframe == DAILY_REPORT 
    date_range = report.sdate.strftime("%B %Y") if report.timeframe == BCYCLE_REPORT 
    ra_file = claims.first.ra_file rescue ''

    pdf = Prawn::Document.new( :page_size => "LETTER", margin: [8.mm,8.mm,15.mm,18.mm]) # Top, Right, bottom, Left
    pdf.text "#{CLINIC_NAME} #{CLINIC_ADDR} #{CLINIC_PHONE} #{CLINIC_FAX}", align: :center, size: 8

    pdf.move_down 5.mm
    pdf.text "#{REPORT_TFRAMES.invert[report.timeframe]} Paid Claims Report For Dr. #{@doc.lname}, Prov# #{@doc.provider_no} Group# #{GROUP_NO}", align: :center, size: 12, style: :bold
    pdf.text "For services paid by MHO in  #{date_range}, RA file #{ra_file}", align: :center, size: 12, style: :bold
    pdf.text "(Sorted by service date, ascending)", align: :center, size: 10
    pdf.move_down 5.mm

    pdf.font "Courier"
    pdf.font_size 8
    @total_hcp_claims = 0
    @total_subm = {'HCP' => 0, 'RMB' => 0, 'WCB' => 0 }
    @total_paid = {'HCP' => 0, 'RMB' => 0, 'WCB' => 0 }
    @servcounts = {'HCP' => 0, 'RMB' => 0, 'WCB' => 0 }
    amt_mismatched = {}

    rows =  [[ "Svc Date", "OHIP#", "Type", "Svcs", "Subm", "Paid", "Claim#", "Acct#", "Visit/Error"]]
    claims.all.each do |cl|
      visit_id_or_error = cl.errcode.empty? ? cl.visit_id : cl.errcode
      rows += [[ cl.date, "#{cl.ohip_num} #{cl.ohip_ver}", cl.pmt_pgm, cl.svcs, sprintf("$%.2f",cl.damt_subm), sprintf("$%.2f",cl.damt_paid), cl.claim_no, cl.accounting_no, visit_id_or_error ]]
      amt_mismatched[rows.size-1] = cl.amt_mismatched?
      @total_hcp_claims += 1 
      @total_subm[cl.pmt_pgm] += cl.damt_subm
      @total_paid[cl.pmt_pgm] += cl.damt_paid
      @servcounts[cl.pmt_pgm] += cl.svcs
    end

    pdf.table rows, cell_style: {inline_format: true} do |t|
        t.cells.border_width = 0 
	t.column_widths = [25.mm, 28.mm, 10.mm, 10.mm, 20.mm, 20.mm, 22.mm, 22.mm, 22.mm ]
        t.header = true 
        t.row(0).font_style = :bold
        t.position = 5.mm
	t.cells.padding = 3
	t.cells.style do |c|
          if amt_mismatched[c.row] 
	    c.background_color = 'CCCCCC' 
	  else
 	    c.background_color = c.row.odd? ? 'EEEEEE' : 'FFFFFF'
	  end
        end
    end
 
    pdf.move_down 10.mm
    pdf.span(190.mm, :position => :center) do
      pdf.text "Total Claims: #{@total_hcp_claims}", size: 9
      totals = [[ '', "HCP", "RMB", "WCB", "Total" ]]
      @submitted = @total_subm.values
      @submitted.push(@submitted.sum)
      totals += [ @submitted.map{|s| sprintf("$%-8.2f",s)}.unshift('Submitted') ]
      @paid = @total_paid.values
      @paid.push(@paid.sum)
      totals += [ @paid.map{|p| sprintf("$%-8.2f",p)}.unshift('Paid') ]
      @services = @servcounts.values
      @services.push(@services.sum)
      totals += [ @services.unshift('Services') ]
      pdf.table totals do |t|
        t.cells.border_width = 1
        t.column_widths = 20.mm 
        t.header = true
        t.row(0).font_style = :bold
      end
    end

    return pdf
  end

# build doctor's cash report 
  def build_cs_report( report, visits )
    
    @doc = Doctor.find(report.doc_id)
    sdate = report.sdate.strftime("%d %b %Y")
    edate = report.edate.strftime("%d %b %Y")
    date_range = report.timeframe == DAILY_REPORT ? sdate : "#{sdate} - #{edate}"
    pdf = Prawn::Document.new( :page_size => "LETTER", margin: [10.mm,10.mm,20.mm,10.mm])

    pdf.text "#{CLINIC_NAME} #{CLINIC_ADDR} #{CLINIC_PHONE} #{CLINIC_FAX}", align: :center, size: 8
    pdf.move_down 5.mm
    pdf.text "#{REPORT_TFRAMES.invert[report.timeframe]} Cash Report For Dr. #{@doc.lname}, Prov# #{@doc.provider_no} Group# #{GROUP_NO}", align: :center, size: 12, style: :bold
    pdf.text "For services performed:  #{date_range}", align: :center, size: 12, style: :bold
    pdf.text "(Sorted by visit time, last to first)", align: :center, size: 10
    pdf.move_down 5.mm
	  
    pdf.font "Courier"
    pdf.font_size 8

    rows =  [[ "Serv Date", "Patient", "OHIP#", "DOB", "Serv.","Type", "Fee", "Status"]]
    @total_cash = 0
    visits.all.each do |v|
      rows += [[ v.entry_ts.strftime("%d/%m/%Y"), v.pat.full_name[0..19], v.pat.ohip_num_full, v.pat.dob.strftime("%d/%m/%Y"), v.cash_pcodes, 'CSH', sprintf("$%.2f",v.total_cash), 'Paid']]
      @total_cash += v.total_cash
    end

    pdf.table rows do |t|
        t.cells.border_width = 0
        t.column_widths = [23.mm, 38.mm, 30.mm, 22.mm, 25.mm, 15.mm, 20.mm, 15.mm ]
        t.header = true
        t.row(0).font_style = :bold
        t.position = 5.mm
        t.cells.padding = 3
        t.cells.style do |c|
           c.background_color = c.row.odd? ? 'EEEEEE' : 'FFFFFF'
        end
    end

    pdf.move_down 10.mm
    pdf.span(190.mm, :position => :center) do
	    pdf.text "Total Cash received: #{sprintf("$%.2f", @total_cash)}", size: 9
    end

	  
    return pdf
  end


# Generate doctor's monthly Pay Stub based on claims paid by MOH
  def build_paystub( paystub, claims_by_day )
    @doc = paystub.doctor
    @month  = Date::MONTHNAMES[paystub.month]
    pdf = Prawn::Document.new( :page_size => "LETTER", margin: [10.mm,10.mm,20.mm,10.mm])

    pdf.text "#{CLINIC_NAME} #{CLINIC_ADDR} #{CLINIC_PHONE} #{CLINIC_FAX}", align: :center, size: 8
    pdf.move_down 10.mm
    pdf.text "Monthly Payment Report For Dr. #{@doc.lname}, Prov# #{@doc.provider_no} Group# #{GROUP_NO}", align: :center, size: 12, style: :bold
    pdf.text "Covering MHO payments disbursed in #{@month} #{paystub.year}", align: :center, size: 12, style: :bold
    pdf.text "(Grouped by service date)", align: :center, size: 10
    pdf.move_down 10.mm

    pdf.font "Courier"
    pdf.font_size 9

    @ttl_claims = @ttl_hcp_svcs = @ttl_rmb_svcs = @ttl_subm_amt = @ttl_paid_amt = 0
    rows =  [[ "Svc Date", "Claims", "Services",  "Pmt Pgm",  "Subm.", "Paid", "Balance", "Date paid" ]]
    claims_by_day.each do |cl|
       rows += [[ cl[0].to_date.strftime("%d/%m/%Y"), cl[1], cl[2], cl[3], cl[4], cl[5], sprintf("%.2f",cl[5]-cl[4]), paystub.date_paid ]]
       @ttl_claims += cl[1]
       @ttl_hcp_svcs += cl[2] if cl[3] == 'HCP'
       @ttl_rmb_svcs += cl[2] if cl[3] == 'RMB'
       @ttl_subm_amt += cl[4]
       @ttl_paid_amt += cl[5]
    end

      pdf.table rows do |t|
        t.cells.border_width = 0 
	t.column_widths = [28.mm, 20.mm, 20.mm, 20.mm, 20.mm, 20.mm, 20.mm  ]
        t.header = true 
        t.row(0).font_style = :bold
        t.position = 15.mm
	t.cells.padding = 3
	t.cells.style do |c|
  	  c.background_color = c.row.odd? ? 'EEEEEE' : 'FFFFFF'
         end
      end
 
      pdf.font_size 10
      pdf.move_down 5.mm
      pdf.span(165.mm, :position => :center) do
        pdf.text "Total claims: #{@ttl_claims}"
        pdf.text "Total services: #{@ttl_hcp_svcs+@ttl_rmb_svcs}"
        pdf.text "Total HCP services: #{@ttl_hcp_svcs}"
        pdf.text "Total RMB services: #{@ttl_rmb_svcs}"
        pdf.move_down 6.mm
	pdf.text "Total submitted amount : #{sprintf("$%.2f",@ttl_subm_amt)}"
	pdf.text "Total OHIP paid amount before MHO deduction:  #{sprintf("$%.2f",@ttl_paid_amt)}" 
	pdf.text "MHO deduction:  #{sprintf("$%.2f",paystub.mho_deduction)}" 
	pdf.text "Monthly Premium payment:  #{sprintf("$%.2f",paystub.monthly_premium_amt)}" 
        pdf.move_down 6.mm
	pdf.text "Received Payments:"
	pdf.text "IFH Payments:  #{sprintf("$%.2f",paystub.ifh_amt)}" 
	pdf.text "Cash payments:  #{sprintf("$%.2f",paystub.cash_amt)}" 
	pdf.text "WCB Payments:  #{sprintf("$%.2f",paystub.wcb_amt)}" 
	pdf.text "Cash deposits:  #{sprintf("$%.2f",paystub.hc_dep_amt)}" 
	other_income = paystub.cash_amt + paystub.wcb_amt + paystub.ifh_amt + paystub.hc_dep_amt 
	pdf.text "Total Received Payments: #{sprintf("$%.2f", other_income)}" 
        pdf.move_down 6.mm
	pdf.text "Total Gross amount:  #{sprintf("$%.2f",paystub.gross_amt)}" 
	pdf.text "(OHIP Amount + Monthly Premium + Received Payments)"
	pdf.text "Clinic deduction (#{@doc.percent_deduction}%):  #{sprintf("$%.2f",paystub.clinic_deduction)}" 
	pdf.text "Total Net amount: #{sprintf("$%.2f",paystub.net_amt)}" 
	pdf.text "(Gross Amount - MHO Deduction - Clinic deduction)"
	pdf.text "Total Paycheck amount: #{sprintf("$%.2f",paystub.chk_amt)}" 
	pdf.text "(Net Amount - Received Payments)"
      end
      
    pdf.move_down 10.mm
    msg = RaMessage.find_by(ra_file: paystub.ra_file)
    if msg.present?
       msg_arr = msg.msg_text.split("\n")
       (index,section) = get_provider_premiums(msg_arr, @doc.provider_no)
       msg_arr.slice!(0,index)

       pdf.span(165.mm, :position => :center) do
	 pdf.text "MHO Provider Payment Information from RA file #{paystub.ra_file}", size: 12, style: :bold
         pdf.move_down 5.mm
#         section2 = get_provider_totals(msg_arr, @doc.provider_no)
	 section2 = []
         section.concat(section2).each do |str|
           pdf.text str
         end
       end
    end

    pdf.move_down 10.mm

    return pdf
  end

  def build_visit_history ( pat )
    date = Date.today.strftime("%d-%b-%Y") 

    pdf = Prawn::Document.new( :page_size => "LETTER", margin: [10.mm,10.mm,10.mm,15.mm])
    pdf.font "Courier"
    pdf.font_size 10

    pdf.text CLINIC_NAME, align: :center, style: :bold, size: 12
    pdf.text CLINIC_ADDR, align: :center 
    pdf.text "tel: #{CLINIC_PHONE} fax: #{CLINIC_FAX}", align: :center
    pdf.move_down 10.mm

    pdf.text "#{pat.full_name} : history of visits to the clinic:", style: :bold, size: 12, align: :center
    pdf.move_down 10.mm

    rows =  [[ "Svc Date", "Doctor", "Diagnosis",  "Ref. Code" ]]
    pat.visits.each do |v|
      next if v.status == CANCELLED
      rows += [[ v.entry_ts.to_date.strftime("%d/%m/%Y"), "Dr. #{v.doctor.lname}", v.diag_descr, v.id ]]
    end

    pdf.table rows do |t|
      t.cells.border_width = 0
      t.column_widths = [35.mm, 45.mm, 80.mm, 20.mm  ]
      t.header = true
      t.row(0).font_style = :bold
      t.position = 15.mm
      t.cells.padding = 3
      t.cells.style do |c|
        c.background_color = c.row.odd? ? 'EEEEEE' : 'FFFFFF'
       end
    end
    
    pdf.move_down 20.mm
    pdf.text "Signature:   _______________________________"
    pdf.move_down 5.mm
    pdf.text "Date: #{date}"

    return pdf
  end

private 

  def label_string ( pat )
     dob = pat.dob.strftime("%d-%b-%Y") rescue ''
     exp_date = pat.hin_expiry.strftime("%m/%y") rescue ''

     "<b>#{pat.lname}, #{pat.fname} (#{pat.sex}), #{pat.age_str}.o</b> 
     #{pat.addr} #{pat.city}, #{pat.prov} 
     DOB: <b>#{dob}</b> File: #{pat.id}
     H#: #{pat.ohip_num} #{pat.ohip_ver} (#{pat.hin_prov})
     Tel: <b>#{pat.phonestr}</b>"
  end

  def addr_label_string ( pat )
     "<b>#{pat.lname}, #{pat.fname} </b> 

     #{pat.addr} #{pat.city}, #{pat.prov} #{pat.postal}"
  end

  # Find PREMIUM PAYMENTS section for given provider, return last line number and section string array
  def get_provider_premiums(arr, prov_no)
    outarr = []; ind = 0;
    arr.each_with_index do |str,i|
            next unless str.match(/PREMIUM PAYMENTS/)
            if arr[i+1,3].join('').match(/#{prov_no}/) 
	       arr[i,16].each do|s|
		 outarr.push("\xC2\xA0#{s}")
		 ind = i
	         break if s.match(/\*{10}/)
	       end
	    end
    end
    return [ind, outarr]
  end

  # Find PAYMENT DISCOUNT SUMMARY section for given provider, return as string array
  def get_provider_totals(arr, prov_no)
    ind  = 0
    outarr = []
    arr.each_with_index do |str,i|
      next unless str.match(/PHYSICIAN PAYMENT DISCOUNT SUMMARY REPORT/)
      ind = i
      break
    end
    arr.slice!(0,ind)

    arr.each_with_index do |s,i|
       next if s.match(/^0078/) && !s.match(/#{prov_no}/)
       next if s.match(/TOTALS TO DATE/)
       next if s.match(/GRAND TOTAL/)
       next if s.match(/HCP-IN/)
       outarr.push(s)
       return outarr if s.match(/\-{70}/)
    end
  end

  end # Forms module

# SMS and voice calls  number format: 19991112222 
  module Nexmo_phone
  require 'nexmo'

  def send_new_visit_sms( visit )
  return unless Rails.env.production?
  return unless Time.now.between?(OFFICE_START_TIME,OFFICE_END_TIME) 

  client = Nexmo::Client.new(
    api_key: Rails.application.credentials[:nexmo_sms][:api_key],
    api_secret: Rails.application.credentials[:nexmo_sms][:api_secret]
  )

# Notify doctor
  if visit.doctor.mobile.present?
    msg = "Appoinment request: #{ visit.patient.full_name } #{visit.patient.age_str} #{visit.patient.sex} \n Reason:  #{visit.reason}"[0..150]  # standard sms length limit; do not send 2-nd concatenated msg 
    client.sms.send(
      from: Rails.application.credentials[:nexmo_sms][:from_number],
      to: visit.doctor.mobile,
      text: msg 
    ) rescue nil
  end

# Notify patient if in Canada and phone is mobile phone 
  phone_number = visit.patient.mobile
  return unless phone_number.present?
  phone_number = "1#{phone_number}" unless phone_number[0] == '1'
  insight = client.number_insight.advanced( number: phone_number, country: 'CA') rescue nil
  return unless insight
  return unless insight.current_carrier.country ==  'CA'
  return unless insight.original_carrier.network_type == 'mobile' 
  return unless insight.valid_number == 'valid'

  client.sms.send(
    from: Rails.application.credentials[:nexmo_voice][:from_number],
    to: phone_number, # 33699436691  19059022448
    text: "Your telemedicine appointment is confirmed. Dr. #{ visit.doctor.lname } will call you shortly" 
  ) rescue nil
  
  end # send_new_visit_sms

# Call doctor's phone during business hours and notify them about new patient  
  def voice_message_to_doctor( visit )
     return unless Rails.env.production?
     return unless Time.now.between?(OFFICE_START_TIME,OFFICE_END_TIME) 
     return unless visit.doctor.mobile.present?
 
    client = Nexmo::Client.new(
      application_id: Rails.application.credentials[:nexmo_voice][:application_id],
      private_key: File.read('config/nexmo_voice.key')
    )

      ncco = [{
        "action": "talk",
        "voiceName": "Tatyana",
        "text": "Здравствуйте доктор #{visit.doctor.lname}! К вам только что зарегистрировался пациент #{visit.patient.full_name}"
      }]

      response = client.voice.create(
        to: [{
          type: 'phone',
#          number: '33699436691'
          number: visit.doctor.mobile 
        }],
        from: {
          type: 'phone',
          number: Rails.application.credentials[:nexmo_voice][:from_number]
        },
        ncco: ncco
      ) rescue nil

#      logger.debug("************ #{response}")

  end # voice_message_to_doctor 
  end # Nexmo_phone module

end # My

