################################################################################
#
# PayerPlan Model => PayerInsurancePlan profile
#
# Copyright (c) 2021 The MITRE Corporation.  All rights reserved.
#
################################################################################

class PayerPlan

  include ActiveModel::Model

  attr_accessor :id, :name, :planid, :period, :contacts, :coverage_area_ids, :formularies_ids

  def initialize(fhir_payerplan)
		@name 	           = fhir_payerplan.name
		@id 		           = fhir_payerplan.id
		@planid            = fhir_payerplan.identifier.first.value
    @period            = fhir_payerplan.period

    @coverage_area_ids = parse_coverage_area_ids(fhir_payerplan)
    @contacts          = parse_contacts(fhir_payerplan)
		@formularies_ids    = parse_formularies_ids(fhir_payerplan)

	end

  #-----------------------------------------------------------------------------

  def parse_coverage_area_ids(fhir_payerplan)
    fhir_payerplan.coverageArea&.map { |location| location.reference.split('/').last }
  end

  #-----------------------------------------------------------------------------

  def parse_formularies_ids(fhir_payerplan)
    fhir_payerplan.coverage&.map(&:extension)&.flatten&.map(&:extension)&.flatten&.map { |formulary| formulary.valueReference.reference.split('/').last }
  end

  #-----------------------------------------------------------------------------

  def parse_contacts(fhir_payerplan)
    contacts = {}
    if fhir_payerplan.contact
      fhir_payerplan.contact.each do |contact_info|
        telecom = {}
        contact_info.telecom&.each do |type|
          telecom[type.system] = type.value
        end
        contacts[contact_info&.name&.text] = telecom
      end
    end

    return contacts
  end

	#-----------------------------------------------------------------------------
end