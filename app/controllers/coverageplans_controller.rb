################################################################################
#
# CoveragePlans Controller
#
# Copyright (c) 2022 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class CoverageplansController < ApplicationController

	before_action :check_formulary_server_connection, :get_plansbyid

	#-----------------------------------------------------------------------------

	# GET /coverageplans

	def index
		@coverageplans = @plansbyid.values
	end

	#-----------------------------------------------------------------------------

	# GET /coverageplans/[id]

	def show
		@plandata = @plansbyid[params[:id].to_sym]
	end

end
