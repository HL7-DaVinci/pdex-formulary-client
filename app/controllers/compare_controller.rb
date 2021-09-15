################################################################################
#
# Compare Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class CompareController < ApplicationController

	before_action :check_formulary_server_connection, only: [ :index ]

	attr_accessor :drugname, :codes 

	#-----------------------------------------------------------------------------

	# GET /compare

	def index
		@codes = nil
		@params = nil 

		get_plansbyid
		if params[:search].length>0 or params[:code].length>0
			@drugname = params[:search].split(' ').first 
			@codes = params[:code].strip.split(',').map(&:strip).join(',')
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
		@cache = Hash.new
			
		searchParams = { _count: 200, _include: ["Basic:subject", "Basic:drug-plan"] } 
		searchParams["subject:MedicationKnowledge.code"] = @codes if @codes and @codes.length > 0
		searchParams["subject:MedicationKnowledge.drug-name"] = @drugname  if @drugname and @drugname.length>0
		searchParams[:code] = "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-InsuranceItemTypeCS|formulary-item"

    @cache[:cps] = []
    @cache[:fds] = []
    @cache[:fis] = []
    get_all(FHIR::Basic, searchParams).each do |resource|
      if resource.resourceType == "Basic"
        @cache[:fis] << resource
      elsif resource.resourceType == "InsurancePlan"
        @cache[:cps] << resource
      else
        @cache[:fds] << resource
      end
      
    end
      
		ClientConnections.cache(session.id.public_id, @cache) unless params[:search].present?
	
	end

	#-----------------------------------------------------------------------------

	# Gets all instances of klass from server

  def get_all(klass = nil, search_params = {})
    replies = get_all_bundles(klass, search_params)
    return nil unless replies

    resources = []
		replies.each do |reply|
      resources.push(reply.entry.collect{ |singleEntry| singleEntry.resource })
    end
    
    resources.compact!
    resources.flatten(1)
	end
	
	#-----------------------------------------------------------------------------

	# Gets all bundles from server when querying for klass

  def get_all_bundles(klass = nil, search_params = {})
		return nil unless klass

		search = { search: { parameters: search_params } }
    reply = @client.search(klass, search).resource
    replies = [].push(reply)
    @search = URI.decode(reply.link.select { |l| l.relation === "self"}.first.url) if reply.link.first
		while replies.last
			replies.push(replies.last.next_bundle)
    end

    replies.compact!
    replies.present? ? replies : nil
	end
	
	#-----------------------------------------------------------------------------

	# Sets @table_headers and @table_rows

	def set_table
		@table_header = @cache[:cps].collect{ |cp| CoveragePlanOld.new(cp.name , cp.id) }
		chosen = @cache[:fis]
    @drugsbyid = build_formulary_drugs(@cache[:fds])
		@table_rows = Hash.new

		chosen.collect!{ |fi| FormularyItem.new(fi, @plansbyid, @drugsbyid) }
		chosen.each do |fi|
			code = fi.rxnorm_code
			plan = fi.plan_id
			@table_rows.has_key?(code) ? @table_rows[code][plan] = fi : @table_rows[code] = { plan => fi }
		end
	end
	
	#-----------------------------------------------------------------------------

	# Sifts through formulary drugs based on search term, returns chosen fds

	# def sift_fds
	# 	return @cache[:fds].clone if params[:search].blank? || ClientConnections.cache_nil?(session.id.public_id)
	# 	@cache[:fds].select{ |fd| fd.code.coding.first.display.upcase.include?(params[:search].upcase) }
	# end

end
