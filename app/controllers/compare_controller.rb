################################################################################
#
# Compare Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class CompareController < ApplicationController
  before_action :check_formulary_server_connection, only: [:index]

  attr_accessor :drugname, :codes

  #-----------------------------------------------------------------------------

  # GET /compare

  def index
    @codes = nil
    @params = nil

    get_plansbyid
    if params[:search].length > 0 or params[:code].length > 0
      @drugname = params[:search].split(" ").first
      @codes = params[:code].strip.split(",").map(&:strip).join(",")
      set_cache
      set_table
      @cache_nil = ClientConnections.cache_nil?(session.id.public_id)
    else
      redirect_to root_path, flash: { error: "Please specify a (partial) drug name, or at least one rxnorm code" }
    end
  end

  #-----------------------------------------------------------------------------
  private

  #-----------------------------------------------------------------------------

  # Sets @cache, either with already cached info or by retrieving info and caching it

  def set_cache
    #	unless @cache = ClientConnections.cache(session.id.public_id)
    @cache = Hash.new
    @cache[:cps] = get_all(FHIR::List, { _count: 200 })
    searchParams = { :_count => 200 }
    searchParams[:code] = @codes if @codes and @codes.length > 0
    searchParams["DrugName:contains"] = @drugname if @drugname and @drugname.length > 0
    # profile = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyDrug"
    # searchParams[:_profile] = profile

    @cache[:fds] = get_all(FHIR::MedicationKnowledge, searchParams)
    ClientConnections.cache(session.id.public_id, @cache) unless params[:search].present?
    #	end
  end

  #-----------------------------------------------------------------------------

  # Gets all instances of klass from server

  def get_all(klass = nil, search_params = {})
    replies = get_all_bundles(klass, search_params)
    return nil unless replies

    resources = []
    replies.each do |reply|
      resources.push(reply.entry.collect { |singleEntry| singleEntry.resource })
    end

    resources.compact!
    resources.flatten(1)
  end

  #-----------------------------------------------------------------------------

  # Gets all bundles from server when querying for klass

  def get_all_bundles(klass = nil, search_params = {})
    return nil unless klass

    search = { search: { parameters: search_params } }
    replies = [].push(@client.search(klass, search).resource)

    while replies.last
      replies.push(replies.last.next_bundle)
    end

    replies.compact!
    replies.present? ? replies : nil
  end

  #-----------------------------------------------------------------------------

  # Sets @table_headers and @table_rows

  def set_table
    @table_header = @cache[:cps].collect { |cp| CoveragePlanOld.new(cp.title, cp.identifier.first.value) }
    chosen = sift_fds.select { |fd| fd.resourceType != "OperationOutcome" }
    @table_rows = Hash.new

    chosen = chosen.map { |fd| FormularyDrug.new(fd, @plansbyid) }
      .select { |fd| fd.valid? }
    chosen = chosen.select { |fd| fd.drug_name.downcase.include?(params[:search].strip.downcase) } if params[:search].present?
    chosen.each do |fd|
      code = fd.rxnorm_code
      plan = fd.plan_id
      @table_rows.has_key?(code) ? @table_rows[code][plan] = fd : @table_rows[code] = { plan => fd }
    end
    flash.now[:alert] = "No plan covers the requested drugs" if @table_rows.blank?
  end

  #-----------------------------------------------------------------------------

  # Sifts through formulary drugs based on search term, returns chosen fds

  def sift_fds
    return @cache[:fds].clone if params[:search].blank? || ClientConnections.cache_nil?(session.id.public_id)
    invalid_fd = @cache[:fds].find { |fd| fd.resourceType == "OperationOutcome" }
    if invalid_fd
      flash.now[:error] = invalid_fd&.issue&.first&.diagnostics
    end
    @cache[:fds].select { |fd| fd.resourceType != "OperationOutcome" }
      .select { |fd| !!(fd&.code&.coding&.first&.display&.upcase&.include?(params[:search]&.strip&.upcase)) }
  end
end
