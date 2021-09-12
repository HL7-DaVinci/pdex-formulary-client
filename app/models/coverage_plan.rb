################################################################################
#
# CoveragePlan Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

# Cut down significantly from Dave's original, my need to revert
class CoveragePlan

  include ActiveModel::Model

	# attr_accessor :name, :id, :summaryurl, :network, :formularyurl, :email, 
	# 								:marketingurl, :planidtype, :planid, :drugs, :tiers
  attr_accessor :name, :id, :planid, :period, :contacts, :coverage_area_ids, :tiers

	def initialize(fhir_coverageplan)
		@name 	           = fhir_coverageplan.name
		@id 		           = fhir_coverageplan.id 
		@planid            = fhir_coverageplan.identifier.first.value 
    @period            = fhir_coverageplan.period

    @coverage_area_ids = parse_coverage_area_ids(fhir_coverageplan)
    @contacts          = parse_contacts(fhir_coverageplan)
		@tiers             = parse_tiers(fhir_coverageplan) 

		
	end


	#-----------------------------------------------------------------------------

  def parse_coverage_area_ids(fhir_coverageplan)
    fhir_coverageplan.coverageArea&.map { |location| location.reference.split('/').last }
  end
  
  #-----------------------------------------------------------------------------

  def parse_contacts(fhir_coverageplan)
    contacts = {}
    if fhir_coverageplan.contact
      fhir_coverageplan.contact.each do |contact_info|
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

	# def parse_drugs(fhir_coverageplan)
	# 	fhir_coverageplan.entry.map(&:item).map(&:reference)
	# end

	#-----------------------------------------------------------------------------

	def parse_tiers(entry)
	  plans = entry.plan
		tiers = {}
		if plans.present?
			plans.each do |plan|
        pharmacyType = plan.type.coding[0].display
        network = plan.network.present? ? plan.network.map(&:display).join(',') : "missing"
        plan.specificCost.each do |tier|
          tiername = tier.category.coding[0].code
          costshare = {}
          tier.benefit[0].cost.each do |share|
            type = share.type.coding[0].code
            value = share.value&.value&.to_i
            if type == "copay"
              costshare[:copayoption] = share.qualifiers[0].coding[0].code
              costshare[:copay] = value
            else
              costshare[:coinsuranceoption] = share.qualifiers[0].coding[0].code
              costshare[:coinsurancerate] = value
            end
          end
          costshare[:network] = network
          if tiers[tiername]
            tiers[tiername][pharmacyType] = costshare
          else
            tiers[tiername] = {pharmacyType => costshare}
          end
        end

			end
			 
		end
    return tiers
	end

	#-----------------------------------------------------------------------------

	def spacesandcaps(codestring)
		codestring.split('-').map(&:capitalize).join(' ')
	end

	#-----------------------------------------------------------------------------

	def self.find_formulary_coverage_plan(pdex_coverage)
		pdex_coverage_identifier = pdex_coverage.identifier.first.value
		COVERAGE_PLAN_MAPPING[pdex_coverage_identifier]
	end

	#-----------------------------------------------------------------------------
	# Internal business logic goes here to link PDex Coverage instance with
	# Formulary coverage plan...

	COVERAGE_PLAN_MAPPING = {
		# PDex Coverage: Formulary Coverage Plan
		"1039399818" => "10207VA0380001"
	}

end
