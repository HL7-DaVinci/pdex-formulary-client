################################################################################
#
# Drug Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class FormularyDrug

  include ActiveModel::Model

	attr_accessor :code, :drug_tier, :drug_class, :prior_authorization, 
									:step_therapy, :quantity_limit

	def initialize(code, drug_tier, drug_class, prior_authorization, step_therapy,
										quantity_limit)
		@code 								= code
		@drug_tier						= drug_tier
		@drug_class						= drug_class
		@prior_authorization	= prior_authorization
		@step_therapy 				= step_therapy
		@quantity_limit				= quantity_limit
	end
	
end