#################################################################################
#
# Plan Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class CoveragePlanOld

	include ActiveModel::Model
  
	  attr_accessor :name, :id
  
	  def initialize(name, id)
		  @name = name
		  @id = id
	  end
  
  end