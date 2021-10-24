################################################################################
#
# CoveragePlans Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class CoverageplansController < ApplicationController

	before_action :check_formulary_server_connection, only: [ :index, :show ]

	#-----------------------------------------------------------------------------

	# GET /coverageplans
	def index
		get_plansbyid
		@coverageplans = @plansbyid.values
    flash.now[:error] = 'No results matching your query' if @coverageplans.empty?
	end

	#-----------------------------------------------------------------------------

	# GET /coverageplans/[id]
	def show
		get_plansbyid
		@plandata = @plansbyid[params[:id].to_sym]
    redirect_to(coverageplans_path, flash: { error: 'Your request returned no result' }) and return  unless @plandata
    # Getting all payers that include a coverage with this formulary
    all_payers = JSON.parse(decompress_hash(session[:payersbyid])).deep_symbolize_keys.values
    plandata_payers = all_payers.filter { |payer| payer[:formularies_ids].include?(params[:id]) }
    @plandata[:payers] = plandata_payers
	end

end
