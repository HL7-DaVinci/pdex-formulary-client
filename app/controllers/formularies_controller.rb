################################################################################
#
# Formularies Controller
#
# Copyright (c) 2022 The MITRE Corporation.  All rights reserved.
#
################################################################################

require "json"

class FormulariesController < ApplicationController
  before_action :check_formulary_server_connection, :get_plansbyid, :redirect_to_home

  #-----------------------------------------------------------------------------

  # GET /formularies

  def index
    if params[:page].present?
      @@bundle = update_page(params[:page], @@bundle)
      @search = session[:formulary_search]
    else
      @@bundle = nil
      search = formularies_search_params
      reply = @client.search(FHIR::MedicationKnowledge, search: search)
      if reply.code == 200
        @@bundle = reply.resource
      elsif reply.code != 404
        @request_faillure = JSON.parse(reply.body)&.to_dot(use_default: true)&.issue&.first&.diagnostics rescue "server internal error occurred"
      end
      # Prepare the query string for display on the page
      request = reply.request.to_dot(use_default: true)
      @search = session[:formulary_search] = "#{request[:method].to_s.capitalize} #{request.url}"
    end

    fhir_formularydrugs = @@bundle ? @@bundle.entry.map(&:resource) : []
    @formularydrugs = []
    error = ""
    fhir_formularydrugs.each do |fhir_formularydrug|
      resource_type = fhir_formularydrug.resourceType
      if resource_type == "OperationOutcome"
        issue = fhir_formularydrug&.issue&.first&.diagnostics
        error = "#{error} #{issue}"
      elsif resource_type == "MedicationKnowledge"
        formulary_drug = FormularyDrug.new(fhir_formularydrug, @plansbyid)
        @formularydrugs << formulary_drug if formulary_drug.valid?
      end
    end
    flash.now[:alert] = "Message from server: #{error}" if error.present?
  end

  #-----------------------------------------------------------------------------

  # GET /formularies/[id]

  def show
    search = { parameters: { _id: params[:id] } }
    chc_payer_id = "9E9CE8B93DE54BA89844A91A0E9A3893" # TODO: TEMPORARY to connect with changehealthcare api. To be removed
    search[:parameters]["chc-payer-id"] = chc_payer_id if cookies[:server_url]&.include?("changehealthcare.com") #TODO: remove this
    reply = @client.search(FHIR::MedicationKnowledge, search: search)
    # Prepare the query string for display on the page
    request = reply.request.to_dot(use_default: true)
    @search = "#{request[:method].to_s.capitalize} #{request.url}"
    if reply.code == 200
      fhir_formularydrug = reply.resource.entry.map(&:resource).first
      @formulary_drug = FormularyDrug.new(fhir_formularydrug, @plansbyid) if fhir_formularydrug
      redirect_to formularies_path, flash: { error: "No Formulary drug matched your search." } if @formulary_drug.nil?
    else
      @request_faillure = JSON.parse(reply.body)&.to_dot(use_default: true)&.issue&.first&.diagnostics rescue "Server internal error"
    end
  end

  #-----------------------------------------------------------------------------
  private

  #-----------------------------------------------------------------------------

  # Performs pagination on the drug formulary list, reading 20 formularies from
  # the server at a time.

  def update_page(page, bundle)
    new_bundle = page.eql?("previous") ? previous_bundle(bundle) : bundle.next_bundle
    return (new_bundle.nil? ? bundle : new_bundle)
  end

  #-----------------------------------------------------------------------------

  # Retrieves the previous 20 formularies from the current position in the
  # bundle.  FHIR::Bundle in the fhir-client gem only provides direct support
  # for the next bundle, not the previous bundle.

  def previous_bundle(bundle)
    link = bundle.previous_link

    if link.present?
      new_bundle = @client.parse_reply(bundle.class, @client.default_format,
                                       @client.raw_read_url(link.url))
      bundle = new_bundle unless new_bundle.nil?
    end

    return bundle
  end

  #-----------------------------------------------------------------------------

  # Contstructing the query search parameters for MedicationKowledge resource
  def formularies_search_params
    search = { parameters: {} }
    search[:parameters][:DrugTier] = params[:drug_tier] if params[:drug_tier].present?
    search[:parameters][:DrugPlan] = params[:coverage] if params[:coverage].present?
    search[:parameters][:code] = params[:code] if params[:code].present?
    # search[:parameters]["DrugName:contains"] = params[:name] if params[:name].present?
    search[:parameters][:DrugName] = params[:name] if params[:name].present?

    chc_payer_id = "9E9CE8B93DE54BA89844A91A0E9A3893" # TODO: TEMPORARY to connect with changehealthcare api. To be removed
    search[:parameters]["chc-payer-id"] = chc_payer_id if cookies[:server_url]&.include?("changehealthcare.com") #TODO: remove this

    search
  end

  #-----------------------------------------------------------------------------
  # Redirect to home page if Unable to query coverage plans
  def redirect_to_home
    redirect_to root_path, flash: { error: "Unable to retrieve coverage plans from the server." } if @request_faillure
  end
end
