################################################################################
#
# Formularies Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class FormulariesController < ApplicationController

	before_action :check_server_connection, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /formularies

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			profile = "http://hl7.org/fhir/us/Davinci-drug-formulary/StructureDefinition/usdf-FormularyDrug"
			parameters = {_profile: profile}
			parameters[:DrugTier] = params[:drug_tier] if params[:drug_tier].present?
			parameters[:DrugPlan] = params[:coverage] if params[:coverage].present?
			parameters[:code] = params[:code] if params[:code].present?
			reply = @client.search(FHIR::MedicationKnowledge, search: { parameters: parameters } )
			@@bundle = reply.resource
		end

		@fhir_formularies = @@bundle.entry.map(&:resource)
	end

	#-----------------------------------------------------------------------------

	# GET /formularies/[id]

	def show
		reply = @client.search(FHIR::MedicationKnowledge, search: { parameters: { id: params[:id] } })
		byebug
		byebug
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

	#-----------------------------------------------------------------------------

	# Performs pagination on the drug formulary list, reading 10 formularies from
	# the server at a time.

	def update_page(page, bundle)
		new_bundle = page.eql?('previous') ? previous_bundle(bundle) : bundle.next_bundle
		return (new_bundle.nil? ? bundle : new_bundle)
	end

	#-----------------------------------------------------------------------------

	# Retrieves the previous 10 formularies from the current position in the 
	# bundle.  FHIR::Bundle in the fhir-client gem only provides direct support 
	# for the next bundle, not the previous bundle.

	def previous_bundle(bundle)
		link = bundle.previous_link

		if link.present?
			new_bundle = @client.parse_reply(bundle.class, @client.default_format, 
									@client.raw_read_url(link.url))
			bundle = new_bundle unless new_bundle.nil?
		end

		return bundle
	end

end