################################################################################
#
# Formularies Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class FormulariesController < ApplicationController

	before_action :connect_to_server, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /formularies

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			reply = @@client.search(FHIR::MedicationKnowledge)
			@@bundle = reply.resource
		end

		@formulary_drugs = @@bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /formularies/[id]

	def show
		reply = @@client.search(FHIR::MedicationKnowledge, 
											search: { parameters: { id: params[:id] } })
		byebug
		byebug
	end

	#-----------------------------------------------------------------------------
	private
	#-----------------------------------------------------------------------------

	# Connect the FHIR client with the specified server and save the connection
	# for future requests.

	def connect_to_server
		if params[:server_url].present?
			@@client = FHIR::Client.new(params[:server_url])
			@@client.use_r4
		elsif !defined?(@@client)
			redirect_to root_path, flash: { error: "Please specify a server" }
		end
	end

	#-----------------------------------------------------------------------------

	# Performs pagination on the drug formulary list, reading 10 formularies from
	# the server at a time.

	def update_page(page, bundle)
		link = nil

		case page
		when 'previous'
			bundle = previous_bundle(bundle)
		when 'next'
			bundle = bundle.next_bundle
		end

		return bundle
	end

	#-----------------------------------------------------------------------------

	# Retrieves the previous 10 formularies from the current position in the 
	# bundle.  FHIR::Bundle in the fhir-client gem only provides direct support 
	# for the next bundle, not the previous bundle.

	def previous_bundle(bundle)
		link = bundle.previous_link

		if link.present?
			new_bundle = @@client.parse_reply(bundle.class, @@client.default_format, 
									@@client.raw_read_url(link.url))
			bundle = new_bundle unless new_bundle.nil?
		end

		return bundle
	end

end