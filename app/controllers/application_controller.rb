################################################################################
#
# Application Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class ApplicationController < ActionController::Base
  rescue_from Rack::Timeout::RequestTimeoutException, with: :handle_timeout

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
    cp_type = "http://terminology.hl7.org/CodeSystem/v3-ActCode|DRUGPOL"
    # Follow pagination links so plans beyond the first page are included
    plans = get_all(FHIR::InsurancePlan, type: cp_type)

    # Save the query self link before the locations call overwrites @search
    session[:query] = @search

    @plansbyid = build_coverage_plans(plans)
    @locationsbyid = locations
    @cp_options = build_coverage_plan_options(plans)
    session[:plansbyid] = compress_hash(@plansbyid.to_json)
    session[:locationsbyid] = compress_hash(@locationsbyid.to_json)
    session[:cp_options] = compress_hash(@cp_options)

    @cp_options
  rescue => exception
    puts "coverage_plans fails:  not connected"
    @cp_options = [["N/A (Must connect first)", "-"]]
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
    profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-InsurancePlanLocation"
    areas = get_all(FHIR::Location, _profile: profile).each_with_object({}) do |resource, areahashbyid|
      areahashbyid[resource.id] = Location.new(resource)
    end

    areas.deep_symbolize_keys
  end

  #-----------------------------------------------------------------------------
  # Read all payer insurance plans from the server
  def payer_plans
    payerplan_type = "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsuranceProductTypeCS|"
    # Follow pagination links so payer plans beyond the first page are included
    payers = get_all(FHIR::InsurancePlan, type: payerplan_type)
    @payersbyid = build_payer_plans(payers)
    session[:payersbyid] = compress_hash(@payersbyid.to_json)

    # get_all sets @search to the self link of the first result bundle
    session[:payersplan_query] = @search
  rescue => exception
    puts "payer plans fails: #{exception}"
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

  # Gets all instances of klass from the server, across all result pages

  def get_all(klass = nil, search_params = {})
    replies = get_all_bundles(klass, search_params)
    return [] unless replies.present?

    resources = []
    replies.each do |reply|
      resources.push(reply.entry.collect { |singleEntry| singleEntry.resource })
    end

    resources.compact!
    resources.flatten(1)
  end

  #-----------------------------------------------------------------------------

  # Gets all bundles from the server when querying for klass, following
  # pagination links until the last page.

  def get_all_bundles(klass = nil, search_params = {})
    return [] unless klass.present?

    search = { search: { parameters: search_params } }
    reply = @client.search(klass, search).resource
    replies = [].push(reply)
    @search = CGI.unescape(reply&.link&.select { |l| l.relation === "self" }.first&.url) if reply&.link&.first
    replies.compact!
    while replies.last
      replies.push(replies.last.next_bundle)
    end

    replies.compact!
    replies.present? ? replies : nil
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

  def build_coverage_plan_options(fhir_plans)
    @cp_options = fhir_plans.collect do |resource|
      [resource.name, resource.id]
    end
    @cp_options.unshift(["All", ""])
  end

  #-----------------------------------------------------------------------------

  def build_coverage_plans(fhir_plans)
    coverageplans = fhir_plans.each_with_object({}) do |resource, planhashbyid|
      planhashbyid[resource.id] = CoveragePlan.new(resource)
    end
    coverageplans.deep_symbolize_keys
  end

  #-----------------------------------------------------------------------------

  def build_payer_plans(fhir_plans)
    payerplans = fhir_plans.each_with_object({}) do |resource, payerhashbyid|
      payerhashbyid[resource.id] = PayerPlan.new(resource)
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
    err = "No response from server: Timed out connecting to server. Server is either down or connection is slow."
    redirect_to root_path, flash: { error: err }
  end

  #-----------------------------------------------------------------------------
  # Check that this session has an established FHIR client connection.
  # Specifically, sets @client and redirects home if nil.

  def check_formulary_server_connection
    session[:foo] = "bar" unless session.id
    raise "session.id is nil" unless session.id
    unless @client = ClientConnections.get(session.id.public_id)
      reset_session
      redirect_to root_path, flash: { error: "Please connect to a formulary server" }
    end
  end
end
