################################################################################
#
# Welcome Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class WelcomeController < ApplicationController

	before_action :connect_to_server, only: [:index]

	def index
		@client = ClientConnections.get(session.id)
	end

	#-----------------------------------------------------------------------------
	private
	#-----------------------------------------------------------------------------

	# Connect the FHIR client with the specified server and save the connection
	# for future requests.

	def connect_to_server
		if params[:server_url].present? && !ClientConnections.set(session.id, params[:server_url])
			redirect_to root_path, flash: { error: "Please specify an accurate url to a formulary server" }
			return nil
		end
		cookies[:server_url] = params[:server_url] if params[:server_url].present?
	end

end