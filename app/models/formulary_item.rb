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
									:warnings, :rxnorm_path, :prior_auth_newstart, :availability_period, :payer_plan,
									:copay, :coinsurancerate, :plan, :formularies_byid, :mailorder, :mail_supplies

	#-----------------------------------------------------------------------------

	def initialize(fhir_formulary, payersbyid, formularies_byid, drugsbyid)
		@id  							= parse_id(fhir_formulary)
    drug              = drugsbyid[parse_reference_id(fhir_formulary.subject.reference).to_sym]
    @drug_name        = drug[:drug_name]
    @rxnorm_code      = drug[:rxnorm_code]
		@formularies_byid = formularies_byid
    @mail_supplies    = []
		#@drug_class				= parse_drug_class(fhir_formulary)
		@rxnorm_path      =    "https://mor.nlm.nih.gov/RxNav/search?searchBy=RXCUI&searchTerm=#{@rxnorm_code}"
		# @formulary_id_path            = "/formularies/#{@id}"
		parse_extensions(fhir_formulary.extension)
		# Test inclusion of drug tier info in formulary drug for display
    @payer_plan = payersbyid.values.find { |payer| payer[:formularies_ids].include?(@plan_id) }
		@tier = @payer_plan[:plans].first[:tiers][@drug_tier.to_sym] if @payer_plan.present?
    costshare = @tier["1 month in network retail".to_sym] if @tier.present?
		if costshare.present?
			@copay = costshare[:copay]
			@coinsurancerate = costshare[:coinsurance]
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

  def parse_reference_id(reference = '')
    return reference.split("/").last
  end

  #-----------------------------------------------------------------------------

 	# Parses the values within the extensions defined by the formulary drug
 	# resource.

	def parse_extensions(fhir_formulary_extensions = [])
		# extensions = fhir_formulary.extension
		# if extensions.present?
    fhir_formulary_extensions.each do |extension|
      if extension.url.include?("DrugTierID")
        @drug_tier = coding_to_string(extension.valueCodeableConcept&.coding).downcase
      elsif extension.url.include?("PharmacyType")
        pharmacy_type = coding_to_string(extension.valueCodeableConcept&.coding).downcase
        if pharmacy_type.include?("mail")
          @mailorder = true
          @mail_supplies << pharmacy_type
        end
      elsif extension.url.include?("PriorAuthorization-extension")
        @prior_auth = extension.valueBoolean
      elsif extension.url.include?("PriorAuthorizationNewStartsOnly")
        @prior_auth_newstart = extension.valueBoolean
      elsif extension.url.include?("StepTherapyLimit-extension")
        @step_therapy = extension.valueBoolean
      elsif extension.url.include?("StepTherapyLimitNewStartsOnly")
        @step_therapy_newstart = extension.valueBoolean
      elsif extension.url.include?("QuantityLimit-extension")
        @quantity_limit = extension.valueBoolean
      elsif extension.url.include?("AvailabilityPeriod")
        @availability_period = period_to_string(extension.valuePeriod)
      elsif extension.url.include?("FormularyReference")
        @plan_id = parse_reference_id(extension.valueReference&.reference)
        @plan = formularies_byid[plan_id&.to_sym]
        # @plan_id_path = "/coverageplans/#{plan_id}"
        # @plan_id_name = plan[:name]
      end
    end
		# else
			# @drug_tier = "Required extensions not specified"
		# end
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