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
			drug_tier_system = "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-DrugTierCS|"
      rxnorm_code_system = "http://www.nlm.nih.gov/research/umls/rxnorm|"
      code = "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-InsuranceItemTypeCS|formulary-item"
			search = { parameters: { _include: "Basic:subject", code: code } }
			search[:parameters]["drug-tier"] = "#{drug_tier_system}#{params[:drug_tier]}" if params[:drug_tier].present?
			search[:parameters]["formulary"] = "InsurancePlan/#{params[:coverage]}" if params[:coverage].present?
			search[:parameters]["subject:MedicationKnowledge.code"] = "#{rxnorm_code_system}#{params[:code]}" if params[:code].present?
			search[:parameters]["subject:MedicationKnowledge.drug-name"] = params[:name] if params[:name].present?
			reply = @client.search(FHIR::Basic, search: search )
			@@bundle = reply.resource
		end
		get_plansbyid
    get_payers_byid
    # Getting formulary plan info if coverage id provided
    @formulary = @plansbyid[params[:coverage]&.to_sym]
		fhir_formularyitems = []
    fhir_formularydrugs = []

    @@bundle.entry.each do |entry|
      resource = entry.resource
      resource.resourceType == "Basic" ? fhir_formularyitems << resource : fhir_formularydrugs << resource
    end

    @drugsbyid =  build_formulary_drugs(fhir_formularydrugs)
		@formularydrugs = []
		fhir_formularyitems.each do |fhir_formularyitem|
			@formularydrugs << FormularyItem.new(fhir_formularyitem, @payersbyid, @plansbyid, @drugsbyid)
		end

		# Prepare the query string for display on the page
  	@search = "<Search String in Returned Bundle is empty>"
  	@search = URI.decode(@@bundle.link.select { |l| l.relation === "self"}.first.url) if @@bundle.link.first
	end

	#-----------------------------------------------------------------------------

	# GET /formularies/[id]

	def show
    code = "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-InsuranceItemTypeCS|formulary-item"
		reply = @client.search(FHIR::Basic, search: { parameters: { _id: params[:id], code: code, _include: "Basic:subject" } })
		@@bundle = reply.resource
    fhir_formularydrugs = []
    fhir_formularyitem = {}
    @@bundle.entry.each do |entry|
      resource = entry.resource
      resource.resourceType == "Basic" ? fhir_formularyitem = resource : fhir_formularydrugs << resource
    end
		# fhir_formularydrug = @@bundle.entry.map(&:resource).first
		get_plansbyid
    @drugsbyid =  build_formulary_drugs(fhir_formularydrugs)
		@formulary_drug = FormularyItem.new(fhir_formularyitem, @plansbyid, @drugsbyid)

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

  #-----------------------------------------------------------------------------


end