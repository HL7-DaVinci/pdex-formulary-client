################################################################################
#
# Location Model
#
# Copyright (c) 2021 The MITRE Corporation.  All rights reserved.
#
################################################################################

class Location

  include ActiveModel::Model

  attr_accessor :id, :address, :name

  def initialize(fhir_location)
    @id      = fhir_location.id
    @address =  fhir_location.address #JSON.parse(fhir_location.address)&.values&.join(', ')
    @name    = fhir_location.name
  end

end