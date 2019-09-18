class CompareController < ApplicationController

	before_action :check_server_connection, only: [ :index ]

	#-----------------------------------------------------------------------------

	# GET /compare

	def index
		unless @cache = ClientConnections.cache(session.id)
			@cache = Hash.new
			@cache[:cps] = get_all(FHIR::List)
			@cache[:fds] = get_all(FHIR::MedicationKnowledge)
			ClientConnections.cache(session.id, @cache)
		end
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
			begin
				replies.push(replies.last.next_bundle)
			rescue
				replies.push(nil)
			end
        end
        replies.compact!
        replies.present? ? replies : nil
    end

end
