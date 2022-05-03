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
    session[:foo] = 'bar' unless session.id

    @client = ClientConnections.get(session.id.public_id)
    @count = session[:formulary_count] || formulary_count
    @cp_count = session[:drugplans_count] || drugplans_count
    @payers_count = session[:payerplans_count] || payerplans_count
    @cache_nil = ClientConnections.cache_nil?(session.id.public_id)
    get_payers_byid
    get_plansbyid
    flash.now[:error] = session.delete(:error) if session[:error]
  end

  #-----------------------------------------------------------------------------
  private

  #-----------------------------------------------------------------------------

  # Connect the FHIR client with the specified server and save the connection
  # for future requests.

  def connect_to_formulary_server
    session[:foo] = 'bar' unless session.id
    raise 'session.id is nil' unless session.id

    # Establish a new session if new server_url provided
    reset_session if params[:server_url].present?
    client_connection = ClientConnections.set(session.id.public_id, params[:server_url])
    session[:error] = client_connection if params[:server_url].present? && client_connection.class != FHIR::Client
    cookies[:server_url] = params[:server_url] if params[:server_url].present?
  end

  #-----------------------------------------------------------------------------

  # Gets count of formularies in server

  def formulary_count
    begin
      # Query/requery the total formulary count if server-url given
      search = { parameters: { _summary: 'count' } }
      count = @client.search(FHIR::MedicationKnowledge, search: search).resource.total
      session[:formulary_count] = count
    rescue StandardError => e
      count = 0
    end
    count
  end

  #-----------------------------------------------------------------------------

  def drugplans_count
    begin
      type = 'http://terminology.hl7.org/CodeSystem/v3-ActCode|DRUGPOL'
      search = { parameters: { type: type, _summary: 'count' } }
      # Query/requery the total drug plan count if server-url given
      count = @client.search(FHIR::InsurancePlan, search: search).resource.total
      session[:drugplans_count] = count
    rescue StandardError => e
      count = 0
    end
    count
  end

  #-----------------------------------------------------------------------------

  def payerplans_count
    begin
      type = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsuranceProductTypeCS|'
      search = { parameters: { type: type, _summary: 'count' } }
      # Query/requery the total payer plan count if server-url given
      count = @client.search(FHIR::InsurancePlan, search: search).resource.total
      session[:payerplans_count] = count
    rescue StandardError => e
      count = 0
    end
    count
  end
end
