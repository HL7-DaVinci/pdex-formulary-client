################################################################################
#
# Formulary Item Model
#
# Copyright (c) 2021 The MITRE Corporation.  All rights reserved.
#
################################################################################

class FormularyItem < Resource

  include ActiveModel::Model

	attr_accessor :drug_tier, :drug_class, :id, :plan_id, :drug_name, :rxnorm_code,
									:prior_auth, :step_therapy, :quantity_limit, :errors, :step_therapy_newstart,
									:warnings, :plan_id_path, :plan_id_name, :rxnorm_path, :prior_auth_newstart,
									:copay, :coinsurancerate, :formulary_id_path, :plan, :plansbyid, :mailorder

	#-----------------------------------------------------------------------------

	def initialize(fhir_formulary, plansbyid, drugsbyid)
		@id  							= parse_id(fhir_formulary)
    drug              = drugsbyid[parse_reference_id(fhir_formulary.subject.reference).to_sym]
    @drug_name        = drug[:drug_name]
    @rxnorm_code      = drug[:rxnorm_code]
		@plansbyid        = plansbyid
		#@drug_class				= parse_drug_class(fhir_formulary)
		@rxnorm_path            =    "https://mor.nlm.nih.gov/RxNav/search?searchBy=RXCUI&searchTerm=" + @rxnorm_code 
		@formulary_id_path            = "/formularies/#{@id}"
		parse_extensions(fhir_formulary)
		@plan = plansbyid[@plan_id.to_sym]
		# Test inclusion of drug tier info in formulary drug for display
		@tier = @plan[:tiers][@drug_tier.to_sym]
		if @tier
			@copay = @tier["1 month in network retail".to_sym][:copay]
			@coinsurancerate = @tier["1 month in network retail".to_sym][:coinsurancerate]			
		else
			@copay = "missing"
			@coinsurancerate = "missing"
		end
	end
	
	#-----------------------------------------------------------------------------
	private
	#-----------------------------------------------------------------------------

	# Isolates the ID from the formulary drug resource.

	def parse_id(fhir_formulary)
		return fhir_formulary.id
	end

	#-----------------------------------------------------------------------------

  def parse_reference_id(reference)
    return reference.split("/").last
  end
  
  #-----------------------------------------------------------------------------

 	# Parses the values within the extensions defined by the formulary drug 
 	# resource.

	def parse_extensions(fhir_formulary)
		extensions = fhir_formulary.extension
		if extensions.present?
			extensions.each do |extension|
				if extension.url.include?("DrugTierID")
					@drug_tier = parse_drug_tier(extension)
        elsif extension.url.include?("PharmacyType")
					if parse_drug_tier(extension).include?("mail")
            @mailorder = true
          end
          
				elsif extension.url.include?("PriorAuthorization-extension")
					@prior_auth = extension.valueBoolean
        elsif extension.url.include?("PriorAuthorizationNewStartsOnly")
					@prior_auth_newstart = extension.valueBoolean
				elsif extension.url.include?("StepTherapyLimit-extension")
					@step_therapy = extension.valueBoolean
        elsif extension.url.include?("StepTherapyLimitNewStartsOnly")
					@step_therapy_newstart = extension.valueBoolean
				elsif extension.url.include?("QuantityLimit")
					@quantity_limit = extension.valueBoolean
				elsif extension.url.include?("DrugPlanReference")
					@plan_id = parse_reference_id(extension.valueReference.reference)
					@plan = plansbyid[plan_id.to_sym]
					@plan_id_path = "/coverageplans/#{plan_id}"
					@plan_id_name = plan[:name]
				end
			end
		else
			@drug_tier = "Required extensions not specified"
		end
	end

	#-----------------------------------------------------------------------------

	def parse_drug_tier(extension)
		if (concept = extension.valueCodeableConcept).present?
			if (coding = concept.coding).present?
				value = code_list(coding)
			else
				value = "Drug tier not specified"
			end
		else
			value = "Codeable concept not present"
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