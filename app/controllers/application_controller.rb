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
  
  def coverage_plans
    # Read all of the coverage plans from the server
    cp_profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-CoveragePlan"
    reply = @client.read(FHIR::List, nil, nil, cp_profile).resource
    @plansbyid  = build_coverage_plans(reply)
    options = build_coverage_plan_options(reply)
    session[:plansbyid] = compress_hash(@plansbyid.to_json)
    session[:cp_options] = compress_hash(options)
    options
    rescue => exception
      puts "coverage_plans fails:  not connected"
      options = [["N/A (Must connect first)", "-"]]
  end

  #-----------------------------------------------------------------------------

  def get_plansbyid
    if session[:plansbyid]
      @plansbyid = JSON.parse(decompress_hash(session[:plansbyid])).deep_symbolize_keys
      @cp_options = decompress_hash(session[:cp_options])
    else
      puts "get_plansbyid:  session[:plansbyid] is nil, calling coverage_plans "
      @plansbyid = nil
      @cp_options = [["N/A (Must connect first)", "-"]]
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

  def build_coverage_plan_options(fhir_list_reply)
    options = fhir_list_reply.entry.collect do |entry| 
      [entry.resource.title, entry.resource.identifier.first.value]
    end
    options.unshift(["All", ""])
  end

  #-----------------------------------------------------------------------------

  def build_coverage_plans (fhir_list_reply)
    coverageplans = fhir_list_reply.entry.each_with_object({}) do | entry, planhashbyid |
      planhashbyid[entry.resource.identifier.first.value] = CoveragePlan.new(entry.resource)
    end
    coverageplans.deep_symbolize_keys
  end

end