################################################################################
#
# Patient Model
#
# Copyright (c) 2021 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Patient

  include ActiveModel::Model

	attr_accessor :names, :id, :photo, :gender, :age, :birth_date, :marital_status, 
									:telecoms, :addresses, :coverage_plan

	def self.init
    patient = Patient.new
    patient.names = [ 'Jane Smith' ]
    patient.id = "12345"
    patient.gender = "Female"
    patient.age = "45"
    patient.birth_date = 45.years.ago
    patient.marital_status = "Married"
    patient.telecoms = [ '123-456-7890']

    address = Address.new
    address.period = nil
    address.lines = [ '123 ABC Lane' ]
    address.city = 'Boston'
    address.state = 'MA'
    address.postalCode = '02134'

    patient.addresses = [ address ]
    patient.coverage_plan = [ "Blue Choice HSA Silver", "10207VA0380001" ]

    patient
	end
	
end