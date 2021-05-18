################################################################################
#
# Address Model
#
# Copyright (c) 2021 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Address

  include ActiveModel::Model

	attr_accessor :period, :lines, :city, :state, :postalCode, :text
	
end