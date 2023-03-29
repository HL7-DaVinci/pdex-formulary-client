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

  def coverage_plans
    # Read all of the insurance drug plans from the server
    cp_type = "http://terminology.hl7.org/CodeSystem/v3-ActCode|DRUGPOL"
    reply = @client.search(FHIR::InsurancePlan, search: { parameters: { type: cp_type}}).resource
    @plansbyid  = JSON.parse(build_coverage_plans(reply).to_json).deep_symbolize_keys
    @formulary_items_and_drugs = formulary_items_and_drugs
    @formulary_items = @formulary_items_and_drugs[:formulary_items]
    @formulary_drugs = @formulary_items_and_drugs[:formulary_drugs]
    @locationsbyid  = locations
    @cp_options = build_coverage_plan_options(reply)
    session[:plansbyid] = compress_hash(@plansbyid.to_json)
    session[:locationsbyid] = compress_hash(@locationsbyid.to_json)
    session[:cp_options] = compress_hash(@cp_options)
    session[:formularyitemsbyid] = compress_hash(@formulary_items.to_json)
    session[:formularydrugsbyid] = compress_hash(@formulary_drugs.to_json)

    # Prepare the query string for display on the page
  	@search = URI.decode(reply.link.select { |l| l.relation === "self"}.first.url) if reply.link.first
    session[:query] = @search
    
    @cp_options
    rescue => exception
      puts "coverage_plans fails:  not connected"
      @cp_options = [["N/A (Must connect first)", "-"]]
      puts exception
  end

  #-----------------------------------------------------------------------------

  def get_plansbyid
    if session[:plansbyid]
      @plansbyid = JSON.parse(decompress_hash(session[:plansbyid])).deep_symbolize_keys
      @locationsbyid = JSON.parse(decompress_hash(session[:locationsbyid])).deep_symbolize_keys
      @cp_options = decompress_hash(session[:cp_options])
      @search = session[:query]
    else
      puts "get_plansbyid:  session[:plansbyid] is #{session[:plansbyid]}, calling coverage_plans "
      @plansbyid = nil
      @cp_options = [["N/A (Must connect first)", "-"]]
      coverage_plans 
    end
  end

  #-----------------------------------------------------------------------------

  def get_formularyItemsById
    if session[:formularyitemsbyid]
      @formularyitemsbyid = JSON.parse(decompress_hash(session[:formularyitemsbyid]))
      @cp_options = decompress_hash(session[:cp_options])
      @search = session[:query]
    else
      puts "get_formularyItemsById: session[:formularyitemsbyid] is nil, calling formulary_items "
      @formularyitemsbyid = nil
      @cp_options = [["N/A (Must connect first)", "-"]]
      formulary_items_and_drugs
    end
  end

  #-----------------------------------------------------------------------------


  def get_formularyDrugsById
    if session[:formularydrugsbyid]
      @formularydrugsbyid = JSON.parse(decompress_hash(session[:formularydrugsbyid]))
      @cp_options = decompress_hash(session[:cp_options])
      @search = session[:query]
    else
      puts "get_formularyDrugsById: session[:formularydrugsbyid] is nil, calling formulary_drugs "
      @formularydrugsbyid = nil
      @cp_options = [["N/A (Must connect first)", "-"]]
      formulary_items_and_drugs
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

  def formulary_items_and_drugs
    profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyItem"
    bundle = @client.search(FHIR::Basic, search: { parameters: {_profile: profile, _include: "Basic:subject", _count: 500 }}).resource&.entry || []
    formulary_drugs = {}
    formulary_items = bundle.each_with_object({}) do | entry, formularyItemById |
      if entry.search.mode == "match"
        formularyItemById[entry.resource.id] = FormularyItem.new(entry.resource, @plansbyid)
      else
        formulary_drugs[entry.resource.id] = MedicationKnowledge.new(entry.resource)
      end
    end
    @formulary_items_and_drugs = {formulary_items: formulary_items.deep_symbolize_keys, formulary_drugs: formulary_drugs.deep_symbolize_keys}
  end
  
  #-----------------------------------------------------------------------------

  def formulary_drugs
    profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyDrug"
    bundle = @client.search(FHIR::MedicationKnowledge, search: { parameters: {_profile: profile}}).resource&.entry || []
    formulary_drugs = bundle.each_with_object({}) do | entry, formularyDrugById |
      formularyDrugById[entry.resource.id] = MedicationKnowledge.new(entry.resource)
    end
    formulary_drugs.deep_symbolize_keys
  end

  #-----------------------------------------------------------------------------

  def payer_plans
    # Read all payer insurance plans from the server
    payerplan_type = "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsuranceProductTypeCS|"

    reply = @client.search(FHIR::InsurancePlan, search: { parameters: { type: payerplan_type}}).resource
    @payersbyid  = build_payer_plans(reply)
    session[:payersbyid] = compress_hash(@payersbyid.to_json)
    
    # Prepare the query string for display on the page
  	@search = URI.decode(reply.link.select { |l| l.relation === "self"}.first.url) if reply.link.first
    session[:payersplan_query] = @search
  
    rescue => exception
      puts "payer plans fails: #{exception}"
  end

  #-----------------------------------------------------------------------------

  def get_payers_byid
    if session[:payersbyid]
      @payersbyid = JSON.parse(decompress_hash(session[:payersbyid])).deep_symbolize_keys
      @search = session[:payersplan_query]
    else
      puts "get_payers_byid:  session[:payersbyid] is #{session[:payersbyid]}, calling payer_plans "
      @payersbyid = nil
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
    @cp_options.unshift(["All", ""])
  end

  #-----------------------------------------------------------------------------

  def build_coverage_plans (fhir_list_reply)
    coverageplans = fhir_list_reply.entry.each_with_object({}) do | entry, planhashbyid |
      planhashbyid[entry.resource.id] = CoveragePlan.new(entry.resource)
    end
    coverageplans.deep_symbolize_keys
  end

  #-----------------------------------------------------------------------------

  def build_payer_plans (fhir_list_reply)
    payerplans = fhir_list_reply.entry.each_with_object({}) do | entry, payerhashbyid |
      payerhashbyid[entry.resource.id] = PayerPlan.new(entry.resource)
    end
    payerplans.deep_symbolize_keys
  end

  #-----------------------------------------------------------------------------

  # Formulary drugs 
  def build_formulary_drugs(fhir_formularydrugs)
    formulary_drugs = fhir_formularydrugs.each_with_object({}) do | resource, drughashbyid |
      drughashbyid[resource.id] = FormularyDrug.new(resource)
    end
    JSON.parse(formulary_drugs.to_json).deep_symbolize_keys
  end
  
  #-----------------------------------------------------------------------------

  # Check that this session has an established FHIR client connection.
  # Specifically, sets @client and redirects home if nil.

  def check_formulary_server_connection
    session[:foo] = "bar" unless session.id   
    raise "session.id is nil"  unless session.id
    unless @client = ClientConnections.get(session.id.public_id)
      session.clear
      redirect_to root_path, flash: { error: "Please connect to a formulary server" }
    end
  end

end