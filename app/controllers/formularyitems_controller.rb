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
      formulary_drug = @formularydrugsbyid.values.find {|drug| formulary_item["subject"]["reference"] == "MedicationKnowledge/" + drug["id"]}
      include_in_results = true
      if params[:coverage].present?
        include_in_results = include_in_results && formulary_item["formulary"]["reference"] == "InsurancePlan/" + params[:coverage]
      end
      if params[:drug_tier].present?
        include_in_results = include_in_results && formulary_item["drug_tier"]["code"] == params[:drug_tier]
      end
      if params[:name].present?
        include_in_results = include_in_results && params[:name].in?(formulary_drug["code"]["display"])
      end
      include_in_results
    end
	end

	#-----------------------------------------------------------------------------

end
