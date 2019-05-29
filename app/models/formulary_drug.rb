################################################################################
#
# Drug Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class FormularyDrug

  include ActiveModel::Model

	attr_accessor :drug_name, :drug_tier, :drug_class, :rxnorm_code, :id, 
									:prior_auth, :step_therapy, :quantity_limit, :errors, 
									:warnings

	#-----------------------------------------------------------------------------

	def initialize(formulary_drug)
		@id  							= parse_id(formulary_drug)
		@drug_name				= parse_drug_name(formulary_drug)
		@drug_tier				= parse_drug_tier(formulary_drug)
		@rxnorm_code 			= parse_rxnorm_code(formulary_drug)
		#@drug_class				= parse_drug_class(formulary_drug)
		@prior_auth 			= parse_prior_auth(formulary_drug)
		@step_therapy 		= parse_step_therapy(formulary_drug)
		@quantity_limit		= parse_quantity_limit(formulary_drug)
	end
	
	#-----------------------------------------------------------------------------

	def parse_id(formulary_drug)
		return formulary_drug.id
	end

	#-----------------------------------------------------------------------------

	# Isolates the drug name from the formulary drug resource.  If the drug name
	# is missing, it posts an error message since it is a required element.

	def parse_drug_name(formulary_drug)
		if (code = formulary_drug.code).present?
			if (coding = code.coding).present?
				value = display_list(coding)
			else
				error(formulary_drug, "Formulary drug.code.coding is not specified")
			end
		else
			error(formulary_drug, "Formulary drug code is not specified")
		end

		return value
	end

	#-----------------------------------------------------------------------------

	def parse_drug_tier(formulary_drug)
		if formulary_drug.extension.present? && (extension = formulary_drug.extension.first)
			if (concept = extension.valueCodeableConcept).present?
				if (coding = concept.coding).present?
					value = display_list(coding)
				else
					error(formulary_drug, "Formulary drug tier value is not specified")
				end
			else
				error(formulary_drug, "Codeable concept for formulary drug tier extension is not present")
			end
		else
			error(formulary_drug, "Formulary drug extension for drug tier is not present")
		end

		return value
	end

	#-----------------------------------------------------------------------------

	# Isolates the RxNorm code from the formulary drug resource.  If the RxNorm
	# code is missing, it posts an error message since it is a required element.

	def parse_rxnorm_code(formulary_drug)
		if (code = formulary_drug.code).present?
			if (coding = code.coding).present?
				value = code_list(coding)
			else
				error(formulary_drug, "Formulary drug.code.coding is not specified") 
			end
		else
			error(formulary_drug, "Formulary drug code is not specified")
		end

		return value
	end

	#-----------------------------------------------------------------------------

	# Isolates the prior authorization flag from the formulary drug resource.

	def parse_prior_auth(formulary_drug)
		if (prior_auth_element = formulary_drug.extension[PRIOR_AUTH]).present?
			value = prior_auth_element.valueBoolean
		else
			warning(formulary_drug, "Prior authorization element not specified")
		end

		return value
	end

	#-----------------------------------------------------------------------------

	# Isolates the step therapy flag from the formulary drug resource

	def parse_step_therapy(formulary_drug)
		if (step_therapy_element = formulary_drug.extension[STEP_THERAPY]).present?
			value = step_therapy_element.valueBoolean
		else
			warning(formulary_drug, "Step therapy element not specified")
		end

		return value
	end

	#-----------------------------------------------------------------------------

	# Isolates the quantity limit flag from the formulary drug resource

	def parse_quantity_limit(formulary_drug)
		if formulary_drug.present?
			if (quantity_limit_element = formulary_drug.extension[QUANTITY_LIMIT]).present?
				value = quantity_limit_element.valueBoolean
			else
				warning(formulary_drug, "Quantity limit element not specified")
			end
		else
			warning(formulary_drug, "Formulary drug is not present")
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