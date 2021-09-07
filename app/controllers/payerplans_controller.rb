################################################################################
#
# PayerPlans Controller  => Payer Insurance Plan profile
#
# Copyright (c) 2021 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class PayerplansController < ApplicationController

	before_action :check_formulary_server_connection, only: [ :index]

	#-----------------------------------------------------------------------------

	# GET /payerplans

	def index
    get_plansbyid
    get_payers_byid
    
		@payerplans = @payersbyid.values
	end

	#-----------------------------------------------------------------------------

end
