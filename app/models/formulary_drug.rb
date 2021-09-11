################################################################################
#
# Formulary Drug Model
#
# Copyright (c) 2021 The MITRE Corporation.  All rights reserved.
#
################################################################################

class FormularyDrug < Resource
  include ActiveModel::Model

	attr_accessor :drug_name, :id, :rxnorm_code
  # :drug_tier, :drug_class, :rxnorm_code, :id, :plan_id, 
	# 								:prior_auth, :step_therapy, :quantity_limit, :errors, 
	# 								:warnings, :plan_id_path, :plan_id_name, :rxnorm_path,
	# 								:copay, :coinsurancerate, :formulary_id_path, :plan, :plansbyid

	#-----------------------------------------------------------------------------
  def initialize(fhir_drug)
		@id  							= fhir_drug.id
		@drug_name				= parse_drug_name(fhir_drug)
		@rxnorm_code 			= parse_rxnorm_code(fhir_drug)
	end
	
	#-----------------------------------------------------------------------------

  # Isolates the drug name from the formulary drug resource.  If the drug name
	# is missing, it posts an error message since it is a required element.

	def parse_drug_name(fhir_drug)
		if (code = fhir_drug.code).present?
			if (coding = code.coding).present?
				value = display_list(coding)
			else
				value = "code.coding not specified"
			end
		else
			value = "Drug name not specified"
		end

		return value
	end

	#-----------------------------------------------------------------------------

  	# Isolates the RxNorm code from the formulary drug resource.  If the RxNorm
	# code is missing, it posts an error message since it is a required element.

	def parse_rxnorm_code(fhir_drug)
		if (code = fhir_drug.code).present?
			if (coding = code.coding).present?
				value = code_list(coding)
			else
				value = "code.coding not specified" 
			end
		else
			value = "RxNorm code not specified"
		end

		return value
	end

 	#-----------------------------------------------------------------------------
  def display_list(list)
		list.map{ |element| element.display }.join(', ')
	end

	#-----------------------------------------------------------------------------

	# Concatenates a list of code elements.

	def code_list(list)
		list.map{ |element| element.code }.join(', ')
	end

end