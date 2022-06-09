################################################################################
#
# Dashboard Controller
#
# Copyright (c) 2020 The MITRE Corporation.  All rights reserved.
#
################################################################################

class DashboardController < ApplicationController
  require "rest-client"
  require "json"
  require "hash_dot"
  require "base64"

  before_action :check_formulary_server_connection, only: [:index]

  #-----------------------------------------------------------------------------
  # Get signed in patient information and coverage_plan
  def index
    connect_to_patient_server if @patient_client == nil

    search_params = { patient: session[:patient_id], type: "http://terminology.hl7.org/CodeSystem/v3-ActCode|DRUGPOL",
                      _include: "Coverage:patient" }
    reply = @patient_client.search(FHIR::Coverage, search: { parameters: search_params })
    if reply.code == 200
      bundle_entries = reply.resource.entry
      if !bundle_entries.empty?
        @patient = bundle_entries.find { |entry| entry.resource.resourceType == "Patient" }&.resource
        pdex_coverage = bundle_entries.find { |entry| entry.resource.resourceType == "Coverage" }&.resource
        coverage_plan_id = CoveragePlan.find_formulary_coverage_plan_id(pdex_coverage)
        get_plansbyid
        @coverage_plan = @plansbyid[coverage_plan_id.to_sym]&.to_dot(use_default: true) if @plansbyid.present?
      end
    else
      request = reply.request
      @search = "#{request.method.capitalize} #{request.url}"
      @request_faillure = JSON.parse(request.body).to_dot(use_default: true).text&.div
    end
    puts "==>DashboardController.index"
  end

  #-----------------------------------------------------------------------------

  # launch:  Pass either params or hardcoded server and client data to the
  # auth_url via redirection

  def launch
    #reset_session    # Get a completely fresh session for each launch.  This is a rails method.
    if params[:client_id].length == 0 #this is a sentinel for unauthenticated access with the patient ID in the client_secret
      session[:client_secret] = session[:patient_id] = params[:client_secret]
      session[:client_id] = params[:client_id]
      session[:iss_url] = params[:iss_url]
      @patient_client = FHIR::Client.new(session[:iss_url])
      @patient_client.use_r4
      # @client.set_bearer_token(session[:access_token])
      puts "==>redirect_to #{dashboard_url}"
      redirect_to patients_path, alert: "Please provide a client id and secret"
    else
      # Let Params values over-ride session values if they are present
      launch = params[:launch] || session[:launch] || "launch"
      iss = (params[:iss_url] || session[:iss_url]).delete_suffix("/metadata")
      session[:client_id] = params[:client_id].gsub /\t/, "" || session[:client_id]
      session[:client_secret] = params[:client_secret].gsub /\t/, "" || session[:client_secret]
      # Get Server Metadata
      rcRequest = RestClient::Request.new(
        :method => :get,
        :url => iss + "/metadata",
      )
      rcResult = JSON.parse(rcRequest.execute)
      session[:auth_url] = rcResult["rest"][0]["security"]["extension"][0]["extension"].select { |e| e["url"] == "authorize" }[0]["valueUri"]
      session[:token_url] = rcResult["rest"][0]["security"]["extension"][0]["extension"].select { |e| e["url"] == "token" }[0]["valueUri"]
      session[:iss_url] = iss
      session[:launch] = launch
      # for Onyx     scope = "launch/patient openid fhirUser offline_access user/ExplanationOfBenefit.read user/Coverage.read user/Organization.read user/Patient.read user/Practitioner.read patient/ExplanationOfBenefit.read patient/Coverage.read patient/Organization.read patient/Patient.read patient/Practitioner.read"
      scope = "launch/patient openid fhirUser offline_access user/*.read patient/*.read"
      scope = scope.gsub(" ", "%20")
      scope = scope.gsub("/", "%2F")
      redirect_to_auth_url = session[:auth_url] +
                             "?response_type=code" +
                             "&redirect_uri=" + login_url +
                             "&aud=" + iss +
                             "&state=98wrghuwuogerg97" +
                             "&scope=" + scope +
                             "&client_id=" + session[:client_id]
      # + "&_format=json"
      puts "===>redirect to #{redirect_to_auth_url}"
      redirect_to redirect_to_auth_url
    end
  rescue StandardError => exception
    reset_session
    err = "Failed to connect: " + exception.message
    redirect_to patients_path, alert: err
  end

  #-----------------------------------------------------------------------------

  # login:  Once authorization has happened, auth server redirects to here.
  #         Use the returned info to get a token
  #         Use the returned token and patientID to get the patient info

  def login
    if params[:error].present? # Authentication Failure
      ## binding.pry
      err = "Authentication Failure: " + params[:error] + " - " + params[:error_description]
      redirect_to patients_path, alert: err
    else
      session[:wakeupsession] = "ok" # using session hash prompts rails session to load
      session[:client_id] = params[:client_id] || session[:client_id] #).gsub! /\t/, ''
      session[:client_secret] = params[:client_secret] || session[:client_secret] #).gsub! /\t/, ''
      code = params[:code]
      auth = "Basic " + Base64.strict_encode64(session[:client_id] + ":" + session[:client_secret])

      begin
        result = RestClient.post(session[:token_url],
                                 {
          grant_type: "authorization_code",
          code: code,
          #   _format: "json",
          redirect_uri: CLIENT_URL + "/login",
        },
                                 {
          :Authorization => auth,
        })
      rescue StandardError => exception
        # byebug
        # reset_session
        redirect_to patients_path, alert: "Failed to connect: " + exception.message and return
      end

      rcResult = JSON.parse(result)
      scope = rcResult["scope"]
      session[:access_token] = rcResult["access_token"]
      session[:refresh_token] = rcResult["refresh_token"]
      session[:token_expiration] = Time.now.to_i + rcResult["expires_in"].to_i
      session[:patient_id] = rcResult["patient"]

      @patient_client = FHIR::Client.new(session[:iss_url])
      @patient_client.use_r4
      @patient_client.set_bearer_token(session[:access_token])
      @patient_client.default_json

      redirect_to dashboard_url, notice: "Successfully signed in"
    end
  end

  #-----------------------------------------------------------------------------
  private

  #-----------------------------------------------------------------------------

  # Connect the FHIR client with the specified patient server and save the connection
  # for future requests.

  def connect_to_patient_server
    puts "==>connect_to_patient_server"
    if session[:client_id].length == 0
      @patient_client = FHIR::Client.new(session[:iss_url])
      @patient_client.use_r4
      return  # We do not have authentication
    end
    if session.empty?
      err = "Session Expired"
      #     binding.pry
      redirect_to root_path, alert: err
    end
    if session[:iss_url].present?
      @patient_client = FHIR::Client.new(session[:iss_url])
      @patient_client.use_r4
      token_expires_in = session[:token_expiration] - Time.now.to_i
      if token_expires_in.to_i < 10 # if we are less than 10s from an expiration, refresh
        get_new_token
      end
      @patient_client.set_bearer_token(session[:access_token])
    end
  rescue StandardError => exception
    reset_session
    err = "Failed to connect: " + exception.message
    redirect_to root_path, alert: err
  end
end
