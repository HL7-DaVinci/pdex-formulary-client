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

	attr_accessor :name, :id, :summaryurl, :network, :formularyurl, :email, :marketingurl, :planidtype, :planid, :drugs

	def initialize(fhir_coverageplan)
		@name = fhir_coverageplan.title
		@id = fhir_coverageplan.id 
		@planid = fhir_coverageplan.identifier.first.value 
		parse_extensions(fhir_coverageplan)
		@drugs = parse_drugs(fhir_coverageplan)
	end


	#-----------------------------------------------------------------------------

 	# Parses the values within the extensions defined by the formulary drug 
 	# resource.

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

end
