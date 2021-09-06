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
    @contacts           = parse_contacts(fhir_coverageplan)
		
    # parse_extensions(fhir_coverageplan)

		@tiers = parse_tiers(fhir_coverageplan) 

		
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

 	#--- Parses the values within the extensions defined by the formulary drug 
	#--- resource.
	#  def parse_extensions(fhir_coverageplan)
	# 	extensions = fhir_coverageplan.extension
	# 	if extensions.present?
	# 			extensions.each do |extension|
	# 				if extension.url.include?("SummaryURL")
	# 					@summaryurl = extension.valueUrl
	# 				elsif extension.url.include?("MarketingURL")
	# 					@marketingurl = extension.valueUrl
	# 				elsif extension.url.include?("EmailPlanContact")
	# 					@email = extension.valueUrl
	# 				elsif extension.url.include?("FormularyURL")
	# 					@formularyurl = extension.valueUrl
	# 				elsif extension.url.include?("PlanID")
	# 					@planidtype  = extension.valueString
	# 				elsif extension.url.include?("Network")
	# 					@network = extension.valueString
	# 				end
	# 			end
	# 	else
	# 		@planid = "Required extensions not specified"
	# 	end
	# end
	 
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
        plan.specificCost.each do |cost|
          tiername = ""
          mailorder= false
          costshares = {}
          tiername = cost.category.coding[0].code
        end

				if extension.url.include?("DrugTierDefinition")
          tiername = ""
         	mailorder= false
					costshares = {}
          extension.extension.each do |drugtier_extension|
            if drugtier_extension.url.include?("drugTierID")
							tiername = drugtier_extension.valueCodeableConcept.coding[0].code
            elsif drugtier_extension.url.include?("mailOrder")
              mailorder = drugtier_extension.valueBoolean
						elsif drugtier_extension.url.include?("costSharing")
              costshare = {}
              copay = 0
              coinsurancerate = 0
              copayoption = ""
              coinsuranceoption = ""
							pharmacytype = ""
              drugtier_extension.extension.each do |costshare_extension|
                if costshare_extension.url.include?("pharmacyType")
                  pharmacytype = costshare_extension.valueCodeableConcept.coding[0].code
                elsif costshare_extension.url.include?("copayAmount")
                  copay = "%d"% costshare_extension.valueMoney.value
								elsif costshare_extension.url.include?("coinsuranceRate")
                  coinsurancerate = "%d" % (costshare_extension.value.to_i * 100)
                elsif costshare_extension.url.include?("coinsuranceOption")
                  coinsuranceoption = costshare_extension.valueCodeableConcept.coding[0].code
                elsif costshare_extension.url.include?("copayOption")
                  copayoption = costshare_extension.valueCodeableConcept.coding[0].code
                else
									puts "Weird stuff in coverage_plan.rb"
                end
							end 

              costshare = {
              	:pharmacytype 			=> pharmacytype,
                :copay 							=> copay,
                :coinsurancerate 		=> coinsurancerate,
                :copayoption 				=> copayoption ,
                :coinsuranceoption 	=> coinsuranceoption
              }

							costshares[pharmacytype] = costshare
            end 
					end 
          tiers[tiername] = {:mailorder => mailorder, :costshares => costshares}
				end
			end
			return tiers 
		end
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
