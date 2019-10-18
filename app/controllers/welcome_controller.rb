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
		@count = formulary_count
		@cp_options = coverage_plans
		@cache_nil = ClientConnections.cache_nil?(session.id)
	end

	#-----------------------------------------------------------------------------
	private
	#-----------------------------------------------------------------------------

	# Connect the FHIR client with the specified server and save the connection
	# for future requests.

	def connect_to_server
		if params[:server_url].present? && !ClientConnections.set(session.id, params[:server_url])
			err = "Connection failed: Ensure provided url points to a valid FHIR server"
			err += " that holds at least one Formulary"
			redirect_to root_path, flash: { error: err }
			return nil
		end
		cookies[:server_url] = params[:server_url] if params[:server_url].present?
	end

	#-----------------------------------------------------------------------------

	# Retrieves the names of the Coverage Plans from the server

	def coverage_plans
		begin
			cp_profile = "http://hl7.org/fhir/us/Davinci-drug-formulary/StructureDefinition/usdf-CoveragePlan"
			reply = @client.read(FHIR::List, nil, nil, cp_profile).resource
			options = reply.entry.collect{|entry| [entry.resource.title, entry.resource.identifier.first.value]}
			options.unshift(["All", ""])
		rescue => exception
			options = [["N/A (Must connect first)", "-"]]
		end
		options
	end

	#-----------------------------------------------------------------------------

	# Gets count of formularies in server

	def formulary_count
		begin
			profile = "http://hl7.org/fhir/us/Davinci-drug-formulary/StructureDefinition/usdf-FormularyDrug"
			search = { parameters: { _profile: profile, _summary: "count" } }
			count = @client.search(FHIR::MedicationKnowledge, search: search ).resource.total
		rescue => exception
			count = 0
		end
		count
	end

end