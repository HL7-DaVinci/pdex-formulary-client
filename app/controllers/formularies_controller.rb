################################################################################
#
# Formularies Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class FormulariesController < ApplicationController

	before_action :check_formulary_server_connection, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /formularies

	def index
		if params[:page].present?
			@@bundle = update_page(params[:page], @@bundle)
		else
			# profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyDrug"
			search = { parameters: {  } }
			search[:parameters][:DrugTier] = params[:drug_tier] if params[:drug_tier].present?
			search[:parameters][:DrugPlan] = params[:coverage] if params[:coverage].present?
			search[:parameters][:code] = params[:code] if params[:code].present?
			search[:parameters]["DrugName:contains"] = params[:name] if params[:name].present?
			reply = @client.search(FHIR::MedicationKnowledge, search: search )
			@@bundle = reply.resource
		end
		get_plansbyid
		fhir_formularydrugs = @@bundle.entry.map(&:resource)

		@formularydrugs = []
		fhir_formularydrugs.each do |fhir_formularydrug| 
			@formularydrugs << FormularyDrug.new(fhir_formularydrug,@plansbyid)
		end

		# Prepare the query string for display on the page
  	@search = "<Search String in Returned Bundle is empty>"
  	@search = URI.decode(@@bundle.link.select { |l| l.relation === "self"}.first.url) if @@bundle.link.first 
	end

	#-----------------------------------------------------------------------------

	# GET /formularies/[id]

	def show
		reply = @client.search(FHIR::MedicationKnowledge, search: { parameters: { _id: params[:id] } })
		@@bundle = reply.resource
		fhir_formularydrug = @@bundle.entry.map(&:resource).first
		get_plansbyid
		@formulary_drug = FormularyDrug.new(fhir_formularydrug,@plansbyid)

		# Prepare the query string for display on the page
  	@search = "<Search String in Returned Bundle is empty>"
  	@search = URI.decode(@@bundle.link.select { |l| l.relation === "self"}.first.url) if @@bundle.link.first 
	end

	#-----------------------------------------------------------------------------
	private
	#-----------------------------------------------------------------------------

	# Performs pagination on the drug formulary list, reading 20 formularies from
	# the server at a time.

	def update_page(page, bundle)
		new_bundle = page.eql?('previous') ? previous_bundle(bundle) : bundle.next_bundle
		return (new_bundle.nil? ? bundle : new_bundle)
	end

	#-----------------------------------------------------------------------------

	# Retrieves the previous 20 formularies from the current position in the 
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