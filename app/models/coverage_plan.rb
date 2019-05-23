################################################################################
#
# Plan Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Plan

  include ActiveModel::Model

	attr_accessor :name, :id, :id_type, :marketing_name, :summary_url,
										:marketing_url, :plan_contact, :network

	def initialize(name, id, id_type, marketing_name, summary_url, marketing_url,
											plan_contact, network)
		@name 						= name
		@id 							= id
		@id_type 					= id_type
		@marketing_name 	= marketing_name
		@summary_url 			= summary_url
		@marketing_url 		= marketing_url
		@plan_contact 		= plan_contact
		@network 					= network
	end

end