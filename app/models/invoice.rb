class Invoice < ApplicationRecord
	
  	belongs_to :patient, inverse_of: :invoices #, counter_cache: true, autosave: true

	default_scope -> { order(date: :desc) }

	validates :date, presence: true
	validates :billto, presence: true, numericality: { only_integer: true }
	validates :patient_id, presence: true
	validates :amount, presence: true, numericality: true
#	validates :doctor_id, numericality: { only_integer: true }


def doctor
    Doctor.find(doctor_id) rescue nil
end

def patient
    Patient.find(patient_id) rescue nil
end

def provider
    Provider.find(billto) rescue nil
end

def filename 
    File.basename(filespec) rescue nil
end

end
