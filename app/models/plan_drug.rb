################################################################################
#
# Plan Drug Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class PlanDrug

  include ActiveModel::Model

	attr_accessor :plan_id, :drug_id

	def initialize(plan_id, drug_id)
		@plan_id 	= plan_id
		@drug_id 	= drug_id
	end
	
end