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

  before_action :check_authentication, only: [:index]

  #-----------------------------------------------------------------------------
  # Get signed in patient information and coverage_plan
  def index
    return if @client.nil?
    # byebug
    type = "http://terminology.hl7.org/CodeSystem/v3-ActCode|DRUGPOL"
    search_params = { patient: session[:patient_id], type: type, _include: "Coverage:patient" }
    reply = @client.search(FHIR::Coverage, search: { parameters: search_params })
    # Retrieving the query url
    request = reply.request.to_dot(use_default: true)
    @search = "#{request[:method].to_s.capitalize} #{request.url}"
    # byebug
    if reply.code == 200
      bundle_entries = reply.resource.entry
      if !bundle_entries.empty?
        @patient = bundle_entries.find { |entry| entry.resource.resourceType == "Patient" }&.resource
        pdex_coverage = bundle_entries.find { |entry| entry.resource.resourceType == "Coverage" }&.resource
        coverage_plan_id = CoveragePlan.find_formulary_coverage_plan_id(pdex_coverage)
        get_plansbyid
        @coverage_plan = @plansbyid[coverage_plan_id.to_sym]&.to_dot(use_default: true) if @plansbyid.present?
      end
    elsif reply.code == 404
      @coverage_plan = nil
    else
      @request_faillure = JSON.parse(reply.body)&.to_dot(use_default: true)&.issue&.first&.diagnostics rescue "Server internal error occured."
    end
  end

  #-----------------------------------------------------------------------------

  # Send request to the server authorization endpoint, providing the client authorization credentials
  def launch
    credentials = session[:credentials]
    options = authentication_metadata
    if (options[:authorize_url] && options[:token_url])
      scope = credentials.scope
      scope = scope.gsub(" ", "%20")
      scope = scope.gsub("/", "%2F")
      server_auth_url = options[:authorize_url] +
                        "?response_type=code" +
                        "&redirect_uri=" + credentials.redirect_url +
                        "&aud=" + credentials.aud +
                        "&state=98wrghuwuogerg97" +
                        "&scope=" + scope +
                        "&client_id=" + credentials.client_id
      puts "===>redirect to #{server_auth_url}"
      redirect_to server_auth_url
    else
      session.delete(:credentials)
      redirect_to root_path, alert: "#{credentials.server_url} is not an auth server: No need to authenticate."
    end
  end

  #-----------------------------------------------------------------------------

  # login:  Once authorization has happened, auth server redirects to here.
  #         Use the returned info to get an access token
  #         Use the returned token and patientID to get the patient info

  def login
    if params[:error].present? # Authentication Failure
      err = "Authentication Failure: #{params[:error]} - #{params[:error_description]}"
      redirect_to patient_access_path, error: err
    else
      cred_attributes = session[:credentials].attributes
      cred_attributes.delete("id")
      saved_cred = ClientConnections.find_by(server_url: session[:credentials].server_url)
      saved_cred ? saved_cred.update(cred_attributes) : session[:credentials].save

      request_access_token(authentication_metadata[:token_url], "authorization_code", params[:code])
      return if session[:access_token].nil?
      ClientConnections.set_bearer_token(session.id.public_id, session[:access_token])

      redirect_to dashboard_url, notice: "Successfully signed in"
    end
  end

  #-----------------------------------------------------------------------------
  private

  # Sending a request to the server token url: getting the access token or refreshing the token
  def request_access_token(token_url, grant_type, code = nil, credentials = session[:credentials])
    claim = {
      :grant_type => grant_type,
      :code => code,
      :refresh_token => (session[:refresh_token] if grant_type == "refresh_token"),
      :redirect_uri => (credentials.redirect_url if grant_type == "authorization_code"),
    }.compact
    auth = {
      :Authorization => basic_auth(credentials.client_id, credentials.client_secret),
    }
    begin
      result = RestClient.post(token_url, claim, auth)
    rescue StandardError => exception
      session.delete_if { |k, v| [:access_token, :refresh_token, :token_expiration].include? k }
      err = grant_type == "refresh_token" ? "Failed to refresh token" : "Failed to authenticate"
      redirect_to patient_access_path, alert: "#{err}: #{exception.message}" and return
    end

    rcResult = JSON.parse(result)
    session[:access_token] = rcResult["access_token"]
    session[:refresh_token] = rcResult["refresh_token"]
    session[:token_expiration] = Time.now.to_i + rcResult["expires_in"].to_i
    session[:patient_id] = rcResult["patient"]
  end

  #-----------------------------------------------------------------------------

  # check if authenticated to auth server
  def check_authentication
    if server_connected? && session[:token_expiration].present?
      token_expires_in = session[:token_expiration] - Time.now.to_i
      if token_expires_in.to_i < 10 # if we are less than 10s from an expiration, refresh
        request_access_token(authentication_metadata[:token_url], "refresh_token")
        return if session[:access_token].nil?
        ClientConnections.set_bearer_token(session.id.public_id, session[:access_token])
      end
      session[:is_authenticated] = true
    else
      reset_session
      redirect_to patient_access_path, error: "Session expired: please reconnect"
    end
  end
end
