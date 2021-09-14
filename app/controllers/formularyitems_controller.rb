################################################################################
#
# FormularItems Controller  => Formulary Item (Basic) profile
#
# Copyright (c) 2021 The MITRE Corporation.  All rights reserved.
#
################################################################################

require 'json'
	
class FormularyitemsController < ApplicationController

	before_action :check_formulary_server_connection, only: [ :index]

	#-----------------------------------------------------------------------------

	# GET /formularyitems

	def index
    get_plansbyid
    get_payers_byid
    get_formularyItemsById
    get_formularyDrugsById
    @formulary_items = @formularyitemsbyid.values.select do |formulary_item|
      if params[:coverage].present?
        formulary_item["formulary"]["reference"] == "InsurancePlan/" + params[:coverage]
      else
        true
      end
    end
	end

	#-----------------------------------------------------------------------------

end
