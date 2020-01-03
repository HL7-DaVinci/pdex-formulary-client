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
		get_plansbyid
		@coverageplans = @plansbyid.values
	end

	#-----------------------------------------------------------------------------

	# GET /coverageplans/[id]

	def show
		get_plansbyid
		@plandata = @plansbyid[params[:id].to_sym]
	end

	#-----------------------------------------------------------------------------
	private
	#-----------------------------------------------------------------------------

			
	# Check that this session has an established FHIR client connection.
	# Specifically, sets @client and redirects home if nil.

	def check_server_connection
		session[:foo] = "bar" unless session.id   
		raise "session.id is nil"  unless session.id
		unless @client = ClientConnections.get(session.id.public_id)
			redirect_to root_path, flash: { error: "Please connect to a formulary server" }
		end
	end

	
end