################################################################################
#
# CoveragePlan Model
#
# Copyright (c) 2022 The MITRE Corporation.  All rights reserved.
#
################################################################################

class CoveragePlan
  include ActiveModel::Model

  attr_accessor(:name, :id, :network, :metadata_links,
                :plan_id_type, :planid, :drugs, :tiers, :plan_code)

  # Validations for required fields
  validates_presence_of :network, :plan_id_type, :tiers, message: "is required but not provided"
  validates_presence_of :plan_code, message: "plan must have a code field with pattern system = http://terminology.hl7.org/CodeSystem/v3-ActCode and code = DRUGPOL"
  validate :presence_of_summary_in_metadata_links

  def presence_of_summary_in_metadata_links
    errors.add("summary_url_extension", "is required but not provided") if metadata_links[:summary].blank?
  end

  # Initialize the coverage plan instance object with fields from the FHIR CoveragePlan resource.
  def initialize(fhir_coverageplan)
    @id = fhir_coverageplan.id
    @name = fhir_coverageplan.title
    @planid = fhir_coverageplan.identifier&.first&.value
    @plan_code = code_fields_present?(fhir_coverageplan.code)
    @metadata_links = {}
    @tiers = {}
    parse_extensions(fhir_coverageplan.extension)

    # We don't currently use the drug list that is part of the coverage plan.
    # Since we want to save this in the session object and keep it small, we
    # will not build this array.
    #
    # @drugs = parse_drugs(fhir_coverageplan)
  end

  #-----------------------------------------------------------------------------

  #-----------------------------------------------------------------------------
  # Retrieves the plan identifier from the fhir coverage plan resource
  def self.find_formulary_coverage_plan_id(pdex_coverage)
    # pdex_coverage_identifier = pdex_coverage.identifier.first.value
    # COVERAGE_PLAN_MAPPING[pdex_coverage_identifier]
    if !pdex_coverage.nil?
      return pdex_coverage.local_class&.find { |c| c&.type&.coding&.first&.code == "plan" }&.value
    end
  end

  #-----------------------------------------------------------------------------
  private :plan_code

  private

  # Check if the code field is present and contains a system and code value
  def code_fields_present?(code)
    if (code.present? && (coding_elmt = code.coding&.first).present?)
      return (coding_elmt.system == "http://terminology.hl7.org/CodeSystem/v3-ActCode" && coding_elmt.code == "DRUGPOL")
    end
    return false
  end

  #-----------------------------------------------------------------------------

  #--- Parses the values within the extensions defined by the formulary drug
  #--- resource.
  def parse_extensions(extensions)
    extensions = [] unless extensions

    extensions.each do |extension|
      if extension.url.include?("SummaryURL")
        @metadata_links[:summary] = extension.valueUrl
      elsif extension.url.include?("MarketingURL")
        @metadata_links[:marketing] = extension.valueUrl
      elsif extension.url.include?("EmailPlanContact")
        @metadata_links[:email] = extension.valueUrl
      elsif extension.url.include?("FormularyURL")
        @metadata_links[:formulary] = extension.valueUrl
      elsif extension.url.include?("PlanID")
        @plan_id_type = extension.valueString
      elsif extension.url.include?("Network")
        @network = extension.valueString
      elsif extension.url.include?("DrugTierDefinition")
        parse_tiers(extension.extension)
      end
    end
  end

  #-----------------------------------------------------------------------------

  def parse_drugs(fhir_coverageplan)
    fhir_coverageplan.entry.map(&:item).map(&:reference)
  end

  #-----------------------------------------------------------------------------

  def parse_tiers(tier_extension_components)
    tiername = ""
    mailorder = false
    costshares = []
    tier_extension_components&.each do |component|
      if component.url&.include?("drugTierID")
        tiername = component.valueCodeableConcept&.coding&.first&.code
      elsif component.url.include?("mailOrder")
        mailorder = component.valueBoolean
      elsif component.url.include?("costSharing")
        costshares << parse_costshares(component.extension)
      end
    end
    @tiers[tiername] = { :mailorder => mailorder, :costshares => costshares }
  end

  #-----------------------------------------------------------------------------

  def parse_costshares(costshare_components)
    costshare = {}

    costshare_components&.each do |component|
      if component.url&.include?("pharmacyType")
        costshare[:pharmacytype] = component.valueCodeableConcept&.coding&.first&.code
      elsif component.url&.include?("copayAmount")
        costshare[:copay] = "%d" % component.valueMoney&.value.to_i
      elsif component.url&.include?("coinsuranceRate")
        costshare[:coinsurancerate] = "%d" % (component.value.to_i * 100)
      elsif component.url&.include?("coinsuranceOption")
        costshare[:coinsuranceoption] = component.valueCodeableConcept&.coding&.first&.code
      elsif component.url&.include?("copayOption")
        costshare[:copayoption] = component.valueCodeableConcept&.coding&.first&.code
      end
    end
    return costshare
  end

  #-----------------------------------------------------------------------------

  def spacesandcaps(codestring)
    codestring.split("-").map(&:capitalize).join(" ")
  end

  #-----------------------------------------------------------------------------
  # Internal business logic goes here to link PDex Coverage instance with
  # Formulary coverage plan...

  COVERAGE_PLAN_MAPPING = {
    # PDex Coverage: Formulary Coverage Plan
    "1039399818" => "10207VA0380001",
  }
end
