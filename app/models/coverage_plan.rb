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

	attr_accessor :name, :id, :summaryurl, :network, :formularyurl, :email, :marketingurl, :planidtype, :planid, :drugs, :tiers

	def initialize(fhir_coverageplan)
		@name = fhir_coverageplan.title
		@id = fhir_coverageplan.id 
		@planid = fhir_coverageplan.identifier.first.value 
		parse_extensions(fhir_coverageplan)
		@drugs = parse_drugs(fhir_coverageplan)
		@drugsbyrxnorm = {}
		@tiers = parse_tiers(fhir_coverageplan) 
		#--- Collect the pharmacy types present in this coverage plan
		@pharmacytypes = {}
		@tiers.each do |tiername, tierdesc| 
			tierdesc[:costshares].each do |pharmtype, costshare|  
               @pharmacytypes[pharmtype] = true
            end  
		 end  
	end


	#-----------------------------------------------------------------------------

 	#--- Parses the values within the extensions defined by the formulary drug 
	#--- resource.
	 def parse_extensions(fhir_coverageplan)
		extensions = fhir_coverageplan.extension
		if extensions.present?
				extensions.each do |extension|
					if extension.url.include?("SummaryURL")
						@summaryurl = extension.valueString
					elsif extension.url.include?("MarketingURL")
						@marketingurl = extension.valueString
					elsif extension.url.include?("EmailPlanContact")
						@email = extension.valueString
					elsif extension.url.include?("FormularyURL")
						@formularyurl = extension.valueString
					elsif extension.url.include?("PlanID")
						@planidtype  = extension.valueString
					elsif extension.url.include?("Network")
						@network = extension.valueString
					end
				end
		else
			@planid = "Required extensions not specified"
		end
	end
	 
	def parse_drugs(fhir_coverageplan)
		fhir_coverageplan.entry.map(&:item).map(&:reference)
	end

	 def parse_tiers(entry)
	    extensions = entry.extension
		tiers = {}
		if extensions.present?
				extensions.each do |extension|
					if extension.url.include?("DrugTierDefinition")
                        tiername = ""
                        mailorder= false
						costshares = {}
                        extension.extension.each do |drugtier_extension|
                            if drugtier_extension.url.include?("DrugTierID")
								tiername = drugtier_extension.valueCodeableConcept.coding[0].code
                            elsif drugtier_extension.url.include?("MailOrder")
                                mailorder = drugtier_extension.valueBoolean
							elsif drugtier_extension.url.include?("CostSharing")
                                costshare = {}
                                copay = 0
                                coinsurancerate = 0
                                copayoption = ""
                                coinsuranceoption = ""
								pharmacytype = ""
                                drugtier_extension.extension.each do |costshare_extension|
                                    if costshare_extension.url.include?("PharmacyType")
                                        pharmacytype = costshare_extension.valueCodeableConcept.coding[0].code
                                    elsif costshare_extension.url.include?("CopayAmount")
                                        copay = costshare_extension.valueMoney.value
                                    elsif costshare_extension.url.include?("CoInsuranceRate")
                                        coinsurancerate = 100*costshare_extension.value
                                    elsif costshare_extension.url.include?("CoinsuranceOption")
                                        coinsuranceoption = costshare_extension.valueCodeableConcept.coding[0].code
                                    elsif costshare_extension.url.include?("CopayOption")
                                        copayoption = costshare_extension.valueCodeableConcept.coding[0].code
                                    else
										flash: { error: "Wierd stuff in Coverage_plan.rb" }
                                    end
								end 
                                costshare = {:pharmacytype => pharmacytype,
                                                :copay => copay,
                                                :coinsurancerate => coinsurancerate,
                                                :copayoption => copayoption ,
                                                :coinsuranceoption => coinsuranceoption}

								costshares[pharmacytype] = costshare
                            end 
						end 
                    	tiers[tiername] = {:mailorder => mailorder, :costshares => costshares}
				end
			end
			return tiers 
		end
	end

	def spacesandcaps(codestring)
		codestring.split('-').map(&:capitalize).join(' ')
	end

end
