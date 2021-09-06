################################################################################
#
# Application Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class ApplicationController < ActionController::Base

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

  def payer_plans
    
  end
  
  #-----------------------------------------------------------------------------

  def coverage_plans
    # Read all of the coverage plans from the server
    cp_type = "http://terminology.hl7.org/CodeSystem/v3-ActCode|DRUGPOL"
    
    reply = @client.search(FHIR::InsurancePlan, search: { parameters: { type: cp_type}}).resource
    @plansbyid  = build_coverage_plans(reply)
    @locationsbyid  = locations
    options = build_coverage_plan_options(reply)
    session[:plansbyid] = compress_hash(@plansbyid.to_json)
    session[:locationsbyid] = compress_hash(@locationsbyid.to_json)
    session[:cp_options] = compress_hash(options)

    # Prepare the query string for display on the page
  	@search = URI.decode(reply.link.select { |l| l.relation === "self"}.first.url) if reply.link.first
    session[:query] = @search
    
    options
    rescue => exception
      puts "coverage_plans fails:  not connected"
      options = [["N/A (Must connect first)", "-"]]
  end

  #-----------------------------------------------------------------------------

  def get_plansbyid
    if session[:plansbyid]
      @plansbyid = JSON.parse(decompress_hash(session[:plansbyid])).deep_symbolize_keys
      @locationsbyid = JSON.parse(decompress_hash(session[:locationsbyid])).deep_symbolize_keys
      @cp_options = decompress_hash(session[:cp_options])
      @search = session[:query]
    else
      puts "get_plansbyid:  session[:plansbyid] is nil, calling coverage_plans "
      @plansbyid = nil
      @cp_options = [["N/A (Must connect first)", "-"]]
      coverage_plans 
    end
  end

  #-----------------------------------------------------------------------------

  def locations
    profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-InsurancePlanLocation"
    bundle = @client.search(FHIR::Location, search: { parameters: { _profile: profile}}).resource&.entry || []
    areas = bundle.each_with_object({}) do | entry, areahashbyid |
      areahashbyid[entry.resource.id] = Location.new(entry.resource)
    end
    
    areas.deep_symbolize_keys
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
    options = fhir_list_reply.entry.collect do |entry| 
      [entry.resource.name, entry.resource.id]
    end
    options.unshift(["All", ""])
  end

  #-----------------------------------------------------------------------------

  def build_coverage_plans (fhir_list_reply)
    coverageplans = fhir_list_reply.entry.each_with_object({}) do | entry, planhashbyid |
      planhashbyid[entry.resource.id] = CoveragePlan.new(entry.resource)
    end
    coverageplans.deep_symbolize_keys
  end

  #-----------------------------------------------------------------------------

  # Check that this session has an established FHIR client connection.
  # Specifically, sets @client and redirects home if nil.

  def check_formulary_server_connection
    session[:foo] = "bar" unless session.id   
    raise "session.id is nil"  unless session.id
    unless @client = ClientConnections.get(session.id.public_id)
      redirect_to root_path, flash: { error: "Please connect to a formulary server" }
    end
  end

end