################################################################################
#
# Formularies Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class FormulariesController < ApplicationController

	before_action :setup_fhir_client, only: [ :index, :show ]

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

	def setup_fhir_client
		if params[:server_url].present?
			@@client = FHIR::Client.new(params[:server_url])
			@@client.use_r4
		end
	end

	#-----------------------------------------------------------------------------

	def update_page(page, bundle)
		link = nil

		case page
			when 'previous'
				link = bundle.previous_link
			when 'next'
				link = bundle.next_link
		end

		if link.present?
			new_bundle = @@client.parse_reply(bundle.class, @@client.default_format, 
									@@client.raw_read_url(link.url))
			bundle = new_bundle unless new_bundle.nil?
		end

		return bundle
	end

end