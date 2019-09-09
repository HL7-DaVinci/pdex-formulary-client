################################################################################
#
# Welcome Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class WelcomeController < ApplicationController

	before_action :connect_to_server, only: [:index]

	def index
		@client = ClientConnections.get(session.id)
		@cp_options = coverage_plans
	end

	#-----------------------------------------------------------------------------
	private
	#-----------------------------------------------------------------------------

	# Connect the FHIR client with the specified server and save the connection
	# for future requests.

	def connect_to_server
		if params[:server_url].present? && !ClientConnections.set(session.id, params[:server_url])
			err = "Connection failed: Ensure provided url points to a valid FHIR server"
			redirect_to root_path, flash: { error: err }
			return nil
		end
		cookies[:server_url] = params[:server_url] if params[:server_url].present?
	end

	#-----------------------------------------------------------------------------

	# Retrieves the names of the Coverage Plans from the server

	def coverage_plans
		begin
			profile_url = "http://hl7.org/fhir/us/Davinci-drug-formulary/StructureDefinition/usdf-CoveragePlan"
			reply = @client.read(FHIR::List, nil, nil, profile_url).resource
			options = reply.entry.collect{|entry| [entry.resource.title, entry.resource.identifier.first.value]}
			options.unshift(["All", ""])
		rescue => exception
			options = [["N/A (Must connect first)", "-"]]
		end
		options
	end

end