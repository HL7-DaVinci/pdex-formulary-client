################################################################################
#
# Dashboard Controller
#
# Copyright (c) 2022 The MITRE Corporation.  All rights reserved.
#
################################################################################

class DashboardController < ApplicationController
  require 'rest-client'
  require 'json'
  require 'base64'

  before_action :connect_to_auth_server, only: [:index]
  @@rsa_key = OpenSSL::PKCS12.new(KEY, KEY_PASSWORD).key # private key to sign jwt
  #-----------------------------------------------------------------------------

  def index
    search_params = { patient: session[:patient_id], type: 'http://terminology.hl7.org/CodeSystem/v3-ActCode|DRUGPOL',
                      _include: 'Coverage:patient' }
    # TODO: first check the status of the response and handle operation outcome accordingly
    bundle_entry = @client.search(FHIR::Coverage, search: { parameters: search_params })&.resource&.entry
    if bundle_entry
      @patient = bundle_entry.find { |entry| entry.resource.resourceType == 'Patient' }&.resource
      pdex_coverage = bundle_entry.find { |entry| entry.resource.resourceType == 'Coverage' }
      drug_plan_class = pdex_coverage&.resource&.local_class&.find { |c| read_code_from_codeableconcept(c.type) == 'plan' }
      insurance_drug_plan_id = drug_plan_class&.value
      get_plansbyid
      @coverage_plan = @plansbyid.select { |_, v| v[:planid] == insurance_drug_plan_id }.values.first

    end
    puts '==>DashboardController.index'
  end

  #-----------------------------------------------------------------------------
  def server_metadata
    # reset_session    # Get a completely fresh session for each launch.  This is a rails method.
    session[:iss_url] = cookies[:iss_url] = params[:iss_url].strip.delete_suffix('/')
    if session[:iss_url].blank?
      redirect_back fallback_location: patients_path,
                    alert: 'Please provide a valid server url.' and return
    end

    session[:client_id] = params[:client_id].strip
    session[:client_secret] = params[:client_secret].strip
    begin
      # For udap server
      rc_request = RestClient::Request.new(
        method: :get,
        url: "#{session[:iss_url]}/.well-known/udap"
      ).execute
      rc_result = JSON.parse(eval(rc_request).to_json)
      session[:registration_url] = rc_result['registration_endpoint']
      session[:auth_url] = rc_result['authorization_endpoint']
      session[:token_url] = rc_result['token_endpoint']
      if session[:client_id].present?
        redirect_to launch_path
      else
        redirect_to registration_path
      end
    rescue StandardError
      begin
        rc_request = RestClient::Request.new(
          method: :get,
          url: "#{session[:iss_url]}/metadata"
        ).execute
        rc_result = JSON.parse(eval(rc_request).to_json) if rc_request
        is_auth_server?(rc_result)
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
    if session[:registration_url].blank?
      redirect_to patients_path,
                  alert: 'Please provide a valid server url.' and return
    end

    # @@rsa_key = OpenSSL::PKey::RSA.new(2048) # public/private key
    # client_credentials = get_registration_claims(@@rsa_key)
    # byebug
    begin
      payload = {
        'software_statement' => get_registration_claims(@@rsa_key),
        'udap' => '1'
      }
      result = RestClient.post(session[:registration_url], payload.to_json, content_type: :json)
      # byebug
    rescue StandardError => e
      reset_session
      err = JSON.parse(e.response)
      redirect_to patients_path, alert: "Registration failed - #{err['error']}: #{err['error_description']} " and return
    end
    rc_result = JSON.parse(result)
    # byebug
    session[:client_id] = rc_result['client_id']
    puts "Successfully registered client to the server. Generated client_id: #{session[:client_id]}"
    redirect_to launch_path
  end

  #-----------------------------------------------------------------------------

  # launch:  Pass either params or hardcoded server and client data to the
  # auth_url via redirection

  def launch
    # For authenticated access: UDAP or smart auth server
    # byebug
    if session[:is_auth_server?].nil? || session[:is_auth_server?] == true
      err = 'This is a secured server: Please provide a client ID and Secret to authenticate'
      redirect_to patients_path, alert: err and return if session[:client_id].blank? || session[:auth_url].blank?

      server_auth_url = set_server_auth_url
      redirect_to server_auth_url
    else # For unauthenticated access
      err = 'Please provide your patient ID in the client secret field to see your data'
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
      err = "Authentication Failure:  #{params[:error]} - #{params[:error_description]}"
      redirect_to patients_path, alert: err
    else
      session[:wakeupsession] = 'ok' # using session hash prompts rails session to load
      session[:client_id] = params[:client_id] || session[:client_id] # ).gsub! /\t/, ''
      session[:client_secret] = params[:client_secret] || session[:client_secret] # ).gsub! /\t/, ''
      code = params[:code]
      if session[:client_secret].present?
        auth = "Basic #{Base64.strict_encode64("#{session[:client_id]}:#{session[:client_secret]}")}"
        payload = {
          'grant_type' => 'authorization_code',
          'code' => code,
          'redirect_uri' => login_url,
          'client_id' => session[:client_id]
        }
        begin
          result = RestClient.post(session[:token_url], payload, { Authorization: auth })
        rescue StandardError => e
          reset_session
          err = JSON.parse(e.response)
          err = "Athentication failed - #{err['error']} - #{err['error_description']}"
          redirect_to patients_path, alert: err and return
        end
      else
        begin
          payload = {
            'grant_type' => 'authorization_code',
            'code' => code,
            'redirect_uri' => login_url,
            'client_assertion_type' => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
            'client_assertion' => get_authentication_claims(@@rsa_key),
            'client_id' => session[:client_id],
            'udap' => '1'
          }
          result = RestClient.post(session[:token_url], payload)
          # byebug
        rescue StandardError => e
          # reset_session
          session[:client_id] = session[:iss_url] = session[:client_secret] = nil
          err = JSON.parse(e.response)
          err = "Authentication failed - #{err['error']}: #{err['error_description']} "
          redirect_to patients_path, alert: err and return
        end
      end

      rc_result = JSON.parse(result)
      # scope = rc_result['scope']
      session[:access_token] = rc_result['access_token']
      session[:refresh_token] = rc_result['refresh_token']
      session[:token_expiration] = Time.now.to_i + rc_result['expires_in'].to_i
      @patient = session[:patient_id] = rc_result['patient']

      redirect_to dashboard_url, notice: "Successfully signed in with patient ID: #{session[:patient_id]}"
    end
  end

  #-----------------------------------------------------------------------------
  private

  #-----------------------------------------------------------------------------

  # Connect the FHIR client with the specified patient server and save the connection
  # for future requests.

  def connect_to_auth_server
    # check_formulary_server_connection
    puts '==>connect_to_auth_server'
    if session.empty? || session[:iss_url].nil?
      redirect_to patients_path,
                  alert: 'Your session has expired. Please reconnect!' and return
    end

    @client = session[:auth_client]
    if @client.present? && ClientConnections.get(session.id.public_id).present?
      if session[:is_auth_server?].nil? || true
        token_expires_in = session[:token_expiration] - Time.now.to_i
        if token_expires_in.to_i < 10 # if we are less than 10s from an expiration, refresh
          err = 'Your session has expired. Please connect again.'
          redirect_to patients_path, alert: err and return if session[:refresh_token].blank?

          token = refresh_token
          return if token.nil?
        end
        @client.set_bearer_token(session[:access_token])
      end
    else
      @client = connect_to_formulary_server(session[:iss_url])

      # @client = FHIR::Client.new(session[:iss_url])
      # @client.use_r4
      if session[:is_auth_server?]
        @client.set_bearer_token(session[:access_token]) if session[:access_token].present?
        @client.default_json
      end
    end
    session[:auth_client] = @client
  rescue StandardError => e
    reset_session
    err = "Failed to connect: #{e.message}"
    redirect_to patients_path, alert: err
  end

  #-----------------------------------------------------------------------------

  # Connect the FHIR client with the specified server and save the connection
  # for future requests.
  def connect_to_formulary_server(server_url)
    session[:foo] = 'bar' unless session.id
    raise 'session.id is nil' unless session.id

    client_connection = ClientConnections.set(session.id.public_id, server_url)
    error = client_connection if client_connection.class != FHIR::Client
    cookies[:server_url] = server_url
    redirect_to patients_path, alert: session.delete(:error) and return if error

    client_connection
  end

  # ------------------------------------------------------------
  # Refresh token from the authorization server
  def refresh_token
    auth = "Basic #{Base64.strict_encode64("#{session[:client_id]}:#{session[:client_secret]}").chomp}"
    rc_result_json = RestClient.post(
      session[:token_url],
      {
        grant_type: 'refresh_token',
        refresh_token: session[:refresh_token]
      },
      {
        Authorization: auth
      }
    )
    rc_result = JSON.parse(rc_result_json)

    session[:patient_id] = rc_result['patient']
    session[:access_token] = rc_result['access_token']
    session[:refresh_token] = rc_result['refresh_token']
    session[:token_expiration] = (Time.now.to_i + rc_result['expires_in'].to_i)
  rescue StandardError => e
    err = "Failed to refresh token: #{e.message}"
    redirect_to patients_path, alert: err and return
  end

  # ------------------------------------------------------------
  # Read Codeable concept code
  def read_code_from_codeableconcept(codeable_concept)
    codeable_concept&.coding&.first&.code
  end
end
