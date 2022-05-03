################################################################################
#
# Application Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class ApplicationController < ActionController::Base
  rescue_from Rack::Timeout::RequestTimeoutException, with: :handle_timeout
  include AuthHelper

  @@plansbyid = {}

  def self.plansbyid
    decompress_hash(session[:plansbyid])
  end

  #-----------------------------------------------------------------------------
  private

  #-----------------------------------------------------------------------------

  def get_patient
    Patient.init
  end

  #-----------------------------------------------------------------------------
  # Read all of the insurance drug plans (Formularies) from the server
  def coverage_plans
    cp_type = 'http://terminology.hl7.org/CodeSystem/v3-ActCode|DRUGPOL'
    reply = @client.search(FHIR::InsurancePlan, search: { parameters: { type: cp_type } }).resource
    @plansbyid = build_coverage_plans(reply)
    @locationsbyid = locations
    @cp_options = build_coverage_plan_options(reply)
    session[:plansbyid] = compress_hash(@plansbyid.to_json)
    session[:locationsbyid] = compress_hash(@locationsbyid.to_json)
    session[:cp_options] = compress_hash(@cp_options)

    # Prepare the query string for display on the page
    @search = URI.decode(reply.link.select { |l| l.relation === 'self' }.first.url) if reply.link.first
    session[:query] = @search

    @cp_options
  rescue StandardError => e
    puts 'coverage_plans fails:  not connected'
    @cp_options = [['N/A (Must connect first)', '-']]
    @locationsbyid ||= {}
    @plansbyid ||= {}
  end

  #-----------------------------------------------------------------------------
  # Retrieving Formularies by id from session object
  def get_plansbyid
    if session[:plansbyid]
      @plansbyid = JSON.parse(decompress_hash(session[:plansbyid])).deep_symbolize_keys
      @locationsbyid = JSON.parse(decompress_hash(session[:locationsbyid])).deep_symbolize_keys
      @cp_options = decompress_hash(session[:cp_options])
      @search = session[:query]
    else
      puts "get_plansbyid:  session[:plansbyid] is #{session[:plansbyid]}, calling coverage_plans "
      coverage_plans
    end
  end

  #-----------------------------------------------------------------------------
  # Read all Locations from the server
  def locations
    profile = 'http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-InsurancePlanLocation'
    bundle = @client.search(FHIR::Location, search: { parameters: { _profile: profile } }).resource&.entry || []
    areas = bundle.each_with_object({}) do |entry, areahashbyid|
      areahashbyid[entry.resource.id] = Location.new(entry.resource)
    end

    areas.deep_symbolize_keys
  end

  #-----------------------------------------------------------------------------
  # Read all payer insurance plans from the server
  def payer_plans
    payerplan_type = 'http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsuranceProductTypeCS|'
    reply = @client.search(FHIR::InsurancePlan, search: { parameters: { type: payerplan_type } }).resource
    @payersbyid = build_payer_plans(reply)
    session[:payersbyid] = compress_hash(@payersbyid.to_json)

    # Prepare the query string for display on the page
    @search = URI.decode(reply.link.select { |l| l.relation === 'self' }.first.url) if reply.link.first
    session[:payersplan_query] = @search
  rescue StandardError => e
    puts "payer plans fails: #{e}"
    @payersbyid ||= {}
  end

  #-----------------------------------------------------------------------------
  # Retrieving payers by id from session object
  def get_payers_byid
    if session[:payersbyid]
      @payersbyid = JSON.parse(decompress_hash(session[:payersbyid])).deep_symbolize_keys
      @search = session[:payersplan_query]
    else
      puts "get_payers_byid:  session[:payersbyid] is #{session[:payersbyid]}, calling payer_plans "
      payer_plans
    end
  end

  #-----------------------------------------------------------------------------

  def compress_hash(h)
    zh = Base64.encode64(Zlib::Deflate.deflate(h.to_json))
  end

  #-----------------------------------------------------------------------------

  def decompress_hash(zh)
    h = JSON.parse(Zlib::Inflate.inflate(Base64.decode64(zh)))
  end

  #-----------------------------------------------------------------------------

  def build_coverage_plan_options(fhir_list_reply)
    @cp_options = fhir_list_reply.entry.collect do |entry|
      [entry.resource.name, entry.resource.id]
    end
    @cp_options.unshift(['All', ''])
  end

  #-----------------------------------------------------------------------------

  def build_coverage_plans(fhir_list_reply)
    coverageplans = fhir_list_reply.entry.each_with_object({}) do |entry, planhashbyid|
      planhashbyid[entry.resource.id] = CoveragePlan.new(entry.resource)
    end
    coverageplans.deep_symbolize_keys
  end

  #-----------------------------------------------------------------------------

  def build_payer_plans(fhir_list_reply)
    payerplans = fhir_list_reply.entry.each_with_object({}) do |entry, payerhashbyid|
      payerhashbyid[entry.resource.id] = PayerPlan.new(entry.resource)
    end
    payerplans.deep_symbolize_keys
  end

  #-----------------------------------------------------------------------------

  # Formulary drugs
  def build_formulary_drugs(fhir_formularydrugs = [])
    formulary_drugs = fhir_formularydrugs.each_with_object({}) do |resource, drughashbyid|
      drughashbyid[resource.id] = FormularyDrug.new(resource)
    end
    JSON.parse(formulary_drugs.to_json).deep_symbolize_keys
  end

  #-----------------------------------------------------------------------------

  # Handle time out request:
  def handle_timeout
    err = 'No response from server: Timed out connecting to server. Server is either down or connection is slow.'
    redirect_to root_path, flash: { error: err }
  end

  #-----------------------------------------------------------------------------
  # Check that this session has an established FHIR client connection.
  # Specifically, sets @client and redirects home if nil.

  def check_formulary_server_connection
    session[:foo] = 'bar' unless session.id
    raise 'session.id is nil' unless session.id

    unless @client = ClientConnections.get(session.id.public_id)
      reset_session
      redirect_to root_path, flash: { error: 'Please connect to a formulary server' }
    end
  end
end
