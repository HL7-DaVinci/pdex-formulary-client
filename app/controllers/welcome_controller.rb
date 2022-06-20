################################################################################
#
# Welcome Controller
#
# Copyright (c) 2022 The MITRE Corporation.  All rights reserved.
#
################################################################################

class WelcomeController < ApplicationController
  before_action :connect_to_formulary_server, only: [:index]

  # Welcome#index: Connects to the server & retrieves the total count of coverage plans and formulary drugs.
  def index
    # solution from https://stackoverflow.com/questions/30772737/rails-4-session-id-occasionally-nil
    session[:foo] = "bar" unless session.id

    @client = ClientConnections.get(session.id.public_id)
    @count = formulary_count
    @cp_count = coverageplan_count
    @cache_nil = ClientConnections.cache_nil?(session.id.public_id)

    get_plansbyid
  end

  #-----------------------------------------------------------------------------
  private

  #-----------------------------------------------------------------------------

  # Connect the FHIR client with the specified server and save the connection for future requests.
  def connect_to_formulary_server
    if params[:server_url].present?
      reset_session
      session[:foo] = "bar" unless session.id
      raise "session.id is nil" unless session.id
      cookies[:server_url] = params[:server_url]
      if !ClientConnections.set(session.id.public_id, params[:server_url])
        err = "Connection failed: Ensure provided url points to a valid FHIR server"
        err += " that holds at least one Formulary"
        redirect_to root_path, flash: { error: err }
      end
    end
  end

  #-----------------------------------------------------------------------------

  # Gets count of formularies in server
  def formulary_count
    return session[:count] if session[:count].present?
    begin
      # profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyDrug"
      search = { parameters: { _summary: "count" } }
      count = @client.search(FHIR::MedicationKnowledge, search: search).resource.total
      session[:count] = count
    rescue => exception
      count = 0
    end
    count
  end

  #-----------------------------------------------------------------------------

  # Gets the count of coverage plans in the server
  def coverageplan_count
    return session[:cp_count] if session[:cp_count].present?
    begin
      # profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-CoveragePlan"
      code = "http://terminology.hl7.org/CodeSystem/v3-ActCode|DRUGPOL"
      search = { parameters: { code: code, _summary: "count" } }
      count = @client.search(FHIR::List, search: search).resource.total
      session[:cp_count] = count
    rescue => exception
      count = 0
    end
    count
  end
end
