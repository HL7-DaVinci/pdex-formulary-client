################################################################################
#
# Application Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class ApplicationController < ActionController::Base
  require "hash_dot"

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
  # Query all coverage plans from the server and save them in the session object for later use.
  def coverage_plans
    # Initialize @plansbyid and @@cp_options
    @plansbyid = {}
    @cp_options = [["N/A (Must connect first)", "-"]]
    return if @client.nil?

    # Read all of the coverage plans from the server (searching by plan code)
    cp_code = "http://terminology.hl7.org/CodeSystem/v3-ActCode|DRUGPOL"
    # cp_profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-CoveragePlan"
    reply = @client.search(FHIR::List, search: { parameters: { code: cp_code } })

    if reply.code == 200
      fhir_list_entries = reply.resource.entry
      @plansbyid = build_coverage_plans(fhir_list_entries)
      @cp_options = build_coverage_plan_options(fhir_list_entries)
      session[:plansbyid] = compress_hash(@plansbyid.to_json)
      session[:cp_options] = compress_hash(@cp_options)
    else
      @request_faillure = JSON.parse(reply.body)&.to_dot(use_default: true)&.issue&.first&.diagnostics
    end

    # Prepare the query string for display on the page
    request = reply.request.to_dot(use_default: true)
    @search = "#{request[:method].to_s.capitalize} #{request.url}"
    session[:query] = @search
  end

  #-----------------------------------------------------------------------------
  # Retrieves the cached coverage plan info and search query.
  def get_plansbyid
    if session[:plansbyid]
      @plansbyid = JSON.parse(decompress_hash(session[:plansbyid])).deep_symbolize_keys
      @cp_options = decompress_hash(session[:cp_options])
      @search = session[:query]
    else
      puts "get_plansbyid:  session[:plansbyid] is nil, calling coverage_plans "
      coverage_plans
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
  # Read an array of List instances and return an [[plan_name, plan_identifier]] or []
  def build_coverage_plan_options(fhir_list_entries)
    fhir_list_entries = [] if fhir_list_entries.nil?
    options = fhir_list_entries.collect do |entry|
      [entry.resource.title, entry.resource.identifier.first.value]
    end
    options.unshift(["All", ""])
  end

  #-----------------------------------------------------------------------------
  # Read an array of List instances and return {:plan_id => CoveragePlan_instance} or {}
  def build_coverage_plans(fhir_list_entries)
    fhir_list_entries = [] if fhir_list_entries.nil?
    errors = []
    coverageplans = fhir_list_entries.each_with_object({}) do |entry, planhashbyid|
      plan = CoveragePlan.new(entry.resource)
      if plan.valid?
        planhashbyid[plan.planid] = plan
      else
        errors.concat(plan.errors.full_messages).uniq!
      end
    end
    flash.now.alert = "Some data returned are not displayed because they are not valid/comformant: #{errors}" if errors.present?
    coverageplans.deep_symbolize_keys
  end

  #-----------------------------------------------------------------------------

  # Check that this session has an established FHIR client connection.
  # Specifically, sets @client and redirects home if nil.

  def check_formulary_server_connection
    session[:foo] = "bar" unless session.id
    raise "session.id is nil" unless session.id
    unless @client = ClientConnections.get(session.id.public_id)
      redirect_to root_path, flash: { error: "Please connect to a formulary server" }
    end
  end
end
