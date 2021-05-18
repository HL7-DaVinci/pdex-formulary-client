################################################################################
#
# CoveragePlans Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class CoverageplansController < ApplicationController

	before_action :check_formulary_server_connection, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /coverageplans

	def index
		get_plansbyid
		@coverageplans = @plansbyid.values
	end

	#-----------------------------------------------------------------------------

	# GET /coverageplans/[id]

	def show
		get_plansbyid
		@plandata = @plansbyid[params[:id].to_sym]
	end

end