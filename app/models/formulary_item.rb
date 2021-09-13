################################################################################
#
# FormularyItem Model => FormularyItem profile
#
# Copyright (c) 2021 The MITRE Corporation.  All rights reserved.
#
################################################################################

class FormularyItem

  include ActiveModel::Model

  attr_accessor :id, :subject, :formulary, :drug_tier, :prior_authorization, :quantity_limit, :step_therapy_limit,
                :status, :period, :pharmacy_type

  def initialize(fhir_formularyitem)
		@id 		             = fhir_formularyitem.id 
    @subject             = fhir_formularyitem.subject

    @extension           = fhir_formularyitem.extension
    @formulary           = find_element_in_extension(@extension, "DrugPlanReference").valueReference
    @drug_tier           = find_element_in_extension(@extension, "DrugTierID").valueCodeableConcept.coding.first
    @prior_authorization = find_element_in_extension(@extension, "PriorAuthorization").valueBoolean
    @quantity_limit      = find_element_in_extension(@extension, "QuantityLimit").valueBoolean
    @step_therapy_limit  = find_element_in_extension(@extension, "StepTherapyLimit").valueBoolean
    @status              = find_element_in_extension(@extension, "AvailabilityStatus").valueCode
    @period              = find_element_in_extension(@extension, "AvailabilityPeriod").valuePeriod
    @pharmacy_type       = find_element_in_extension(@extension, "PharmacyType").valueCodeableConcept.coding.first
    
	end
  


  private

  def find_element_in_extension(extensions, reference_key)
    extensions.each do |extension|
      if extension.url.include?(reference_key)
        return extension
      end
    end
  end
end