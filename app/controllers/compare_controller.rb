class CompareController < ApplicationController

	before_action :check_server_connection, only: [ :index ]

	#-----------------------------------------------------------------------------

	# GET /compare

	def index
		set_cache
		sift_fds
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

	# Sifts through formulary drugs based on search term, sets @chosen_fds

	def sift_fds
		return @chosen_fds = @cache[:fds].clone if params[:search].blank?
		@chosen_fds = @cache[:fds].select{ |fd| fd.code.coding.display.include?(params[:search]) }
	end

end
