################################################################################
#
# CoveragePlan Model
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

# Formulary Profile of the FHIR R4 InsurancePlan
# See https://build.fhir.org/ig/HL7/davinci-pdex-formulary/StructureDefinition-usdf-Formulary.html
class CoveragePlan < Resource
  include ActiveModel::Model

  attr_accessor :name, :id, :planid, :period, :type

  def initialize(fhir_coverageplan)
    @name = fhir_coverageplan.name
    @id = fhir_coverageplan.id
    @planid = fhir_coverageplan.identifier.first.value
    @period = fhir_coverageplan.period
    @type = coding_to_string(fhir_coverageplan.type&.first&.coding)
  end

  #-----------------------------------------------------------------------------

  def spacesandcaps(codestring)
    codestring.split("-").map(&:capitalize).join(" ")
  end

  #-----------------------------------------------------------------------------

  def self.find_formulary_coverage_plan(pdex_coverage)
    pdex_coverage_identifier = pdex_coverage.identifier.first.value
    COVERAGE_PLAN_MAPPING[pdex_coverage_identifier]
  end

  #-----------------------------------------------------------------------------
  # Internal business logic goes here to link PDex Coverage instance with
  # Formulary coverage plan...

  COVERAGE_PLAN_MAPPING = {
    # PDex Coverage: Formulary Coverage Plan
    "1039399818" => "10207VA0380001",
  }
end
