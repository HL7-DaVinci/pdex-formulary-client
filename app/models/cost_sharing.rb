################################################################################
#
# Code Sharing Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class CodeSharing

  include ActiveModel::Model

	attr_accessor	:pharmacy_type, :copay_amount, :copay_opt, :coinsurance_rate, 
										:coinsurance_opt

	def initialize(pharmacy_type, copay_amount, copay_opt, coinsurance_rate,
										coinsurance_opt)
		@pharmacy_type 			= pharmacy_type
		@copay_amount 			= copay_amount
		@copay_opt 					= copay_opt
		@coinsurance_rate 	= coinsurance_rate
		@coinsurance_opt 		= coinsurance_opt
	end

end
