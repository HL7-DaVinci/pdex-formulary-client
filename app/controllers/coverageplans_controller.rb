################################################################################
#
# CoveragePlans Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class CoverageplansController < ApplicationController

	before_action :check_server_connection, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /coverageplans

	def index
		@coverageplans = ApplicationController::plansbyid.values
	end

	#-----------------------------------------------------------------------------

	# GET /coverageplans/[id]

	def show
		@plandata = ApplicationController::plansbyid[params[:id]]
	end

	#-----------------------------------------------------------------------------
	private
	#-----------------------------------------------------------------------------

			
	# Check that this session has an established FHIR client connection.
	# Specifically, sets @client and redirects home if nil.

	def check_server_connection
		unless @client = ClientConnections.get(session.id)
			redirect_to root_path, flash: { error: "Please connect to a formulary server" }
		end
	end

	
end