class CompareController < ApplicationController

	before_action :check_server_connection, only: [ :index ]

	#-----------------------------------------------------------------------------

	# GET /compare

	def index
		set_cache
		set_table
	end

	#-----------------------------------------------------------------------------
	private
	#-----------------------------------------------------------------------------

	# Check that this session has an established FHIR client connection.
	# Specifically, sets @client and redirects home if nil.

	def check_server_connection
		unless @client = ClientConnections.get(session.id)
			redirect_to root_path, flash: { error: "Please connect to a formulary server" }
		end
	end

	#-----------------------------------------------------------------------------

	# Sets @cache, either with already cached info or by retrieving info and caching it

	def set_cache
		unless @cache = ClientConnections.cache(session.id)
			@cache = Hash.new
			@cache[:cps] = get_all(FHIR::List)
			@cache[:fds] = get_all(FHIR::MedicationKnowledge)
			ClientConnections.cache(session.id, @cache)
		end
	end

	#-----------------------------------------------------------------------------

	# Gets all instances of klass from server

    def get_all(klass = nil, count = 200)
        replies = get_all_bundles(klass, count)
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

    def get_all_bundles(klass = nil, count = 200)
		return nil unless klass
		search = { search: { parameters: { _count: count } } }
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
		@table_header = @cache[:cps].collect{ |cp| CoveragePlan.new(cp.title , cp.identifier.first.value) }
		chosen = sift_fds
		@table_rows = Hash.new
		chosen.collect!{ |fd| FormularyDrug.new(fd) }
		chosen.each do |fd|
			code = fd.rxnorm_code
			plan = fd.plan_id
			@table_rows.has_key?(code) ? @table_rows[code][plan] = fd : @table_rows[code] = { plan => fd }
		end
	end
	
	#-----------------------------------------------------------------------------

	# Sifts through formulary drugs based on search term, returns chosen fds

	def sift_fds
		return @cache[:fds].clone if params[:search].blank?
		@cache[:fds].select{ |fd| fd.code.coding.first.display.upcase.include?(params[:search].upcase) }
	end

end
