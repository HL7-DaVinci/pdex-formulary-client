################################################################################
#
# Application Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class ApplicationController < ActionController::Base
  require 'dalli'
  before_action :setup_dalli, :connect_to_server

  @@plansbyid = {}

  def self.plansbyid
    decompress_hash(session[:plansbyid])
    get_cache("plansbyid")
  end

  #-----------------------------------------------------------------------------
  private
  #-----------------------------------------------------------------------------

  def coverage_plans
    # Read all of the coverage plans from the server
    #cp_profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-CoveragePlan"
    reply = @client.read(FHIR::List, nil, nil, nil).resource
    @plansbyid  = build_coverage_plans(reply)
    @cp_options = build_coverage_plan_options(reply)
    set_cache("plansbyid",@plansbyid)
    set_cache("cp_options", @cp_options)
    rescue => exception
      puts "coverage_plans fails:  not connected"
      options = [["N/A (Must connect first)", "-"]]
  end

  #-----------------------------------------------------------------------------

  def get_plansbyid
    if get_cache("plansbyid")
      @plansbyid = get_cache("plansbyid")
      @cp_options = get_cache("cp_options")
    else
      puts "get_plansbyid:  get_cache(\"plansbyid\") is nil, calling coverage_plans "
      @plansbyid = nil
      @cp_options = [["N/A (Must connect first)", "-"]]
      coverage_plans 
    end
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
    #binding.pry 
    #coverageplans.deep_symbolize_keys
  end

  def setup_dalli
    options = { :namespace => "formulary", :compress => true }
    @dalli_client = Dalli::Client.new('localhost:11211', options)
  end

  # Utility accessors that reference session data

  def set_cache(variable,value)
    puts "dalli: set #{variable}-#{session.id.public_id}"
    @dalli_client.set("#{variable}-#{session.id.public_id}",value)
  end

  def get_cache(variable)
    puts "dalli: get #{variable}-#{session.id.public_id}"
    @dalli_client.get("#{variable}-#{session.id.public_id}")
  end

  def get_iss_url
    @dalli_client.get("iss_url-#{session.id.public_id}")
  end
  def set_iss_url(url)
    @dalli_client.set("iss_url-#{session.id.public_id}",url)
  end

  def get_client_id
    @dalli_client.get("client_id-#{session.id.public_id}")
    #session[:client_id]
  end
  def set_client_id(id)
    @dalli_client.set("client_id-#{session.id.public_id}",id)
    #session[:client_id]
  end

    # Get the FHIR server url
    def server_url
        url = (params[:server_url] || session[:server_url])
        url = url.strip if url 
     end

  def connect_to_server
    puts "==>connect_to_server"
    # if client_id.length == 0 
    #   @client = FHIR::Client.new(iss_url)
    #   @client.use_r4
    #   return  # We do not have authentication
    # end
    if session.empty? 
      err = "Session Expired"
      #     binding.pry 
      redirect_to root_path, alert: err
    end
    if server_url.present?
      @client = FHIR::Client.new(server_url)
      @client.use_r4
	  @client.use_r4
	  @client.additional_headers = { 'Accept-Encoding' => 'identity' }  # 
	  @client.set_basic_auth("fhiruser","change-password")
    #   token_expires_in = token_expiration - Time.now.to_i
    #   if token_expires_in.to_i < 10   # if we are less than 10s from an expiration, refresh
    #     get_new_token
    #   end
    #   @client.set_bearer_token(access_token)
    cookies[:server_url] = server_url
    session[:server_url] = server_url   
    end
  rescue StandardError => exception
    reset_session
    err = "Failed to connect: " + exception.message
    redirect_to root_path, alert: err
  end


end