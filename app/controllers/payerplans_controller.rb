################################################################################
#
# PayerPlans Controller  => Payer Insurance Plan profile
#
# Copyright (c) 2021 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'

class PayerplansController < ApplicationController

	before_action :check_formulary_server_connection, only: [ :index]

	#-----------------------------------------------------------------------------

	# GET /payerplans

	def index
    get_plansbyid
    get_payers_byid
		@payerplans = @payersbyid.values
    flash.now[:error] = 'No results matching your query' if @payerplans.empty?
	end

	#-----------------------------------------------------------------------------

  # GET /payerplans/:id
  def show
    get_plansbyid
    get_payers_byid
		@payerplan = @payersbyid[params[:id].to_sym]
    redirect_to payerplans_path, flash: { error: 'Your request returned no result' } unless @payerplan
  end

  #-----------------------------------------------------------------------------
end
