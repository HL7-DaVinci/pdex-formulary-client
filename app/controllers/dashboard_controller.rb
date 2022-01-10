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
  require "base64"

  before_action :check_formulary_server_connection, only: [:index]
  @@rsa_key = OpenSSL::PKey::RSA.new(2048) # public/private key to sign cert|jwt
  #-----------------------------------------------------------------------------

  def index
    connect_to_patient_server if @patient_client.nil?

    @patient = @patient_client.read(FHIR::Patient, "PDexPatient1").resource
    if @patient
      pdex_coverage_bundle = @patient_client.search(FHIR::Coverage,
                                                    search: {
                                                      parameters: { patient: @patient.id },
                                                    }).resource
      pdex_coverage = pdex_coverage_bundle.entry.first.resource

      coverage_plan_id = CoveragePlan.find_formulary_coverage_plan(pdex_coverage)
      coverage_plan_bundle = @client.search(FHIR::List,
                                            search: {
                                              parameters: { identifier: coverage_plan_id },
                                            }).resource
      @coverage_plan = coverage_plan_bundle.entry.first.resource
    end
    puts "==>DashboardController.index"
  end

  #-----------------------------------------------------------------------------
  def server_metadata
    # reset_session    # Get a completely fresh session for each launch.  This is a rails method.
    session[:iss_url] = cookies[:iss_url] = params[:iss_url].strip.delete_suffix("/")
    redirect_back fallback_location: patients_path, alert: "Please provide a valid server url." and return if session[:iss_url].blank?
    session[:client_id] = params[:client_id].strip
    session[:client_secret] = params[:client_secret].strip
    begin
      # For udap server
      rcRequest = RestClient::Request.new(
        :method => :get,
        :url => session[:iss_url] + "/.well-known/udap",
      ).execute
      rcResult = JSON.parse(eval(rcRequest).to_json)
      session[:registration_url] = rcResult["registration_endpoint"]
      session[:auth_url] = rcResult["authorization_endpoint"]
      session[:token_url] = rcResult["token_endpoint"]
      if session[:client_id].present?
        redirect_to launch_path
      else
        redirect_to registration_path
      end
    rescue
      begin
        rcRequest = RestClient::Request.new(
          :method => :get,
          :url => session[:iss_url] + "/metadata",
        ).execute
        rcResult = JSON.parse(eval(rcRequest).to_json) if rcRequest
        is_auth_server?(rcResult)
        redirect_to launch_path
      rescue StandardError => exception
        reset_session
        err = "Unable to retrieve the server metada: #{exception.message}"
        redirect_back fallback_location: patients_path, alert: err and return
      end
      # err = "#{exception.message}: Unable to retrieve UDAP metadata. Server may not support UDAP workflows."
    end
  end

  #-----------------------------------------------------------------------------
  # UDAP client registration
  def registration
    redirect_to patients_path, alert: "Please provide a valid server url." and return if session[:registration_url].blank?
    # @@rsa_key = OpenSSL::PKey::RSA.new(2048) # public/private key
    client_credentials = get_registration_claims(@@rsa_key)
    # byebug
    begin
      result = RestClient.post(session[:registration_url],
                               {
                                 software_statement: client_credentials,
                                 certifications: [generate_cert(@@rsa_key)],
                                 udap: "1",
                               }.to_json, {
        content_type: :json,
      })
      # byebug
    rescue StandardError => exception
      err = JSON.parse(exception.response)
      redirect_to patients_path, alert: "Registration failed - #{exception.message}: #{err["error_description"]} " and return
    end
    rcResult = JSON.parse(result)
    # byebug
    session[:client_id] = rcResult["client_id"]
    redirect_to launch_path
  end

  #-----------------------------------------------------------------------------

  # launch:  Pass either params or hardcoded server and client data to the
  # auth_url via redirection

  def launch
    # For authenticated access: UDAP or smart auth server
    if (session[:is_auth_server?] == true || nil)
      err = "This is a secured server: Please provide a client ID and Secret to authenticate"
      redirect_to patients_path, alert: err and return if (session[:client_id].blank? || session[:auth_url].blank?)
      server_auth_url = set_server_auth_url()
      redirect_to server_auth_url
    else # For unauthenticated access
      err = "Please provide your patient ID in the client secret field to see your data"
      redirect_to patients_path, alert: err and return if session[:client_secret].blank?
      session[:patient_id] = session[:client_secret]
      redirect_to dashboard_path, notice: "Signed in with Patient ID: #{session[:patient_id]}"
    end
    cookies.clear
  end

  #-----------------------------------------------------------------------------

  # login:  Once authorization has happened, auth server redirects to here.
  #         Use the returned info to get a token
  #         Use the returned token and patientID to get the patient info

  def login
    if params[:error].present? # Authentication Failure
      err = "Authentication Failure: " + params[:error] + " - " + params[:error_description]
      redirect_to patients_path, alert: err
    else
      session[:wakeupsession] = "ok" # using session hash prompts rails session to load
      session[:client_id] = params[:client_id] || session[:client_id] #).gsub! /\t/, ''
      session[:client_secret] = params[:client_secret] || session[:client_secret] #).gsub! /\t/, ''
      code = params[:code]
      if session[:client_secret].present?
        auth = "Basic " + Base64.strict_encode64(session[:client_id] + ":" + session[:client_secret])
        begin
          result = RestClient.post(session[:token_url],
                                   {
            grant_type: "authorization_code",
            code: code,
            redirect_uri: CLIENT_URL + "/login",
          },
                                   {
            :Authorization => auth,
          })
        rescue StandardError => exception
          reset_session
          err = JSON.parse(exception.response)
          err = "Athentication failed - #{err["error"]} - #{err["error_description"]}"
          redirect_to patients_path, alert: err and return
        end
      else
        begin
          result = RestClient.post(session[:token_url],
                                   {
                                     grant_type: "authorization_code",
                                     code: code,
                                     redirect_uri: login_url,
                                     client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
                                     client_assertion: get_authentication_claims(@@rsa_key),
                                     udap: "1",
                                   })
          # byebug
        rescue StandardError => exception
          reset_session
          err = JSON.parse(exception.response)
          err = "Authentication failed - #{err["error"]}: #{err["error_description"]} "
          redirect_to patients_path, alert: err and return
        end
      end

      rcResult = JSON.parse(result)
      scope = rcResult["scope"]
      session[:access_token] = rcResult["access_token"]
      session[:refresh_token] = rcResult["refresh_token"]
      session[:token_expiration] = Time.now.to_i + rcResult["expires_in"].to_i
      @patient = session[:patient_id] = rcResult["patient"]

      redirect_to dashboard_url, notice: "Signed in with patient ID: #{session[:patient_id]}"
    end
  end

  #-----------------------------------------------------------------------------
  private

  #-----------------------------------------------------------------------------

  # Connect the FHIR client with the specified patient server and save the connection
  # for future requests.

  def connect_to_patient_server
    puts "==>connect_to_patient_server"
    redirect_to patients_path, alert: "Your session has expired. Please reconnect!" and return if (session.empty? || session[:iss_url].nil?)
    @patient_client = session[:patient_client]
    if @patient_client.present?
      if (session[:is_auth_server?] == nil || true)
        token_expires_in = session[:token_expiration] - Time.now.to_i
        if token_expires_in.to_i < 10 # if we are less than 10s from an expiration, refresh
          err = "Your session has expired. Please connect again."
          redirect_to patients_path, alert: err and return if session[:refresh_token].blank?
          token = refresh_token()
          return if token.nil?
        end
        @patient_client.set_bearer_token(session[:access_token])
      end
    else
      @patient_client = FHIR::Client.new(session[:iss_url])
      @patient_client.use_r4
      if !!session[:is_auth_server?]
        @patient_client.set_bearer_token(session[:access_token]) if session[:access_token].present?
        @patient_client.default_json
      end
    end
    session[:patient_client] = @patient_client
  rescue StandardError => exception
    reset_session
    err = "Failed to connect: " + exception.message
    redirect_to patients_path, alert: err
  end

  # ------------------------------------------------------------
  # Refresh token from the authorization server
  def refresh_token
    auth = "Basic " + Base64.strict_encode64(session[:client_id] + ":" + session[:client_secret]).chomp
    rcResultJson = RestClient.post(
      session[:token_url],
      {
        grant_type: "refresh_token",
        refresh_token: session[:refresh_token],
      },
      {
        :Authorization => auth,
      }
    )
    rcResult = JSON.parse(rcResultJson)

    session[:patient_id] = rcResult["patient"]
    session[:access_token] = rcResult["access_token"]
    session[:refresh_token] = rcResult["refresh_token"]
    session[:token_expiration] = (Time.now.to_i + rcResult["expires_in"].to_i)
  rescue StandardError => exception
    err = "Failed to refresh token: " + exception.message
    redirect_to patients_path, alert: err and return
  end
end
