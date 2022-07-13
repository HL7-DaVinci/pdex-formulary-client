################################################################################
#
# Welcome Controller
#
# Copyright (c) 2022 The MITRE Corporation.  All rights reserved.
#
################################################################################

class WelcomeController < ApplicationController
  before_action do
    connect_to_formulary_server(params[:server_url])
  end

  # GET / : Connects to the server & retrieves the total count of coverage plans and formulary drugs.
  def index
    # solution from https://stackoverflow.com/questions/30772737/rails-4-session-id-occasionally-nil
    session[:foo] = "bar" unless session.id
    reset_session if !server_connected?
    @count = formulary_count
    @cp_count = coverageplan_count
    @cache_nil = ClientConnections.cache_nil?(session.id.public_id)

    get_plansbyid
    flash.now[:error] = @connection.delete(:error) if @connection
  end

  #-----------------------------------------------------------------------------
  private

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
      # code = "http://terminology.hl7.org/CodeSystem/v3-ActCode|DRUGPOL"
      # search = { parameters: { code: code, _summary: "count" } }
      search = { parameters: { _summary: "count" } }
      count = @client.search(FHIR::List, search: search).resource.total
      session[:cp_count] = count
    rescue => exception
      count = 0
    end
    count
  end
end
