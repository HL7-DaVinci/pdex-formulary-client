################################################################################
#
# Welcome Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class WelcomeController < ApplicationController

	before_action :connect_to_formulary_server, only: [:index]

	def index
		# solution from https://stackoverflow.com/questions/30772737/rails-4-session-id-occasionally-nil
		session[:foo] = "bar" unless session.id 

		@client       = ClientConnections.get(session.id.public_id)
		@count        = formulary_count
		@cp_count     = coverageplan_count 
		@cp_options   = coverage_plans
    @payers_count = payerplans_count
		@cache_nil    = ClientConnections.cache_nil?(session.id.public_id)

    get_payers_byid
		get_plansbyid
	end

	#-----------------------------------------------------------------------------
	private
	#-----------------------------------------------------------------------------

	# Connect the FHIR client with the specified server and save the connection
	# for future requests.

	def connect_to_formulary_server
		session[:foo] = "bar" unless session.id   
		raise "session.id is nil"  unless session.id
		if params[:server_url].present? && !ClientConnections.set(session.id.public_id, params[:server_url])
			err = "Connection failed: Ensure provided url points to a valid FHIR server"
			err += " that holds at least one Formulary"
			redirect_to root_path, flash: { error: err }
			session[:plansbyid] = nil
			session[:cp_options] = [["N/A (Must connect first)", "-"]]
      session[:payersbyid] = nil
      session[:locationsbyid] = nil
			return nil
		end
		cookies[:server_url] = params[:server_url] if params[:server_url].present?
	end

	#-----------------------------------------------------------------------------

	# Gets count of formularies in server

	def formulary_count
		begin
			# profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyDrug"
			search = { parameters: { _summary: "count" } }
			count = @client.search(FHIR::MedicationKnowledge, search: search ).resource.total
		rescue => exception
			count = 0
		end
		count
	end

  #-----------------------------------------------------------------------------

	def coverageplan_count
		begin
			# profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-CoveragePlan"
      type = "http://terminology.hl7.org/CodeSystem/v3-ActCode|DRUGPOL"
			search = { parameters: { type: type, _summary: "count" } }
			count = @client.search(FHIR::InsurancePlan, search: search ).resource.total
		rescue => exception
			count = 0
		end
		count
	end

  #-----------------------------------------------------------------------------

  def payerplans_count
    begin
      type = "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsuranceProductTypeCS|"
      search = { parameters: { type: type, _summary: "count" } }
      count = @client.search(FHIR::InsurancePlan, search: search ).resource.total
    rescue => exception
      count = 0
    end
    count
  end

end