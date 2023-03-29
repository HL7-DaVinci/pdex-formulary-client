################################################################################
#
# FormularyMedicationKnowledge Model => MedicationKnowledge profile
#
# Copyright (c) 2021 The MITRE Corporation.  All rights reserved.
#
################################################################################

class MedicationKnowledge

  include ActiveModel::Model

  attr_accessor :id, :status, :code, :synonym, :dose_form, :related_medication_knowledge, :medicine_classification

  def initialize(fhir_medicationknowledge)
		@id 		                      = fhir_medicationknowledge.id 
    @code                         = fhir_medicationknowledge.code.coding.first
    @status                       = fhir_medicationknowledge.status
    @synonym                      = fhir_medicationknowledge.synonym
    @dose_form                    = fhir_medicationknowledge.doseForm
    @related_medication_knowledge = fhir_medicationknowledge.relatedMedicationKnowledge
    @medicine_classification      = fhir_medicationknowledge.medicineClassification
    
	end
end