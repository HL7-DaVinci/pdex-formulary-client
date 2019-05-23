################################################################################
#
# DrugTier Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class DrugTier

  include ActiveModel::Model

	attr_accessor :drug_tier, :mail_order

	def initialize(name, rxnorm_code)
		@drug_tier 		= drug_tier
		@rxnorm_code 	= rxnorm_code
	end
	
end