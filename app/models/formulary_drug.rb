################################################################################
#
# Drug Model
#
# Copyright (c) 2022 The MITRE Corporation.  All rights reserved.
#
################################################################################

class FormularyDrug < Resource
  include ActiveModel::Model

  attr_accessor(:drug_name, :drug_tier, :rxnorm_code, :id, :plan_id,
                :plan, :plan_name, :plan_path, :plan_tierdesc, :rxnorm_path,
                :coverage_restrictions, :formulary_id_path)

  # Validations for required fields
  validates_presence_of :drug_name, :rxnorm_code, :plan_id, :drug_tier, message: "must be provided"
  #-----------------------------------------------------------------------------

  def initialize(fhir_formulary, plansbyid)
    @id = fhir_formulary.id
    @drug_name = parse_drug_name(fhir_formulary)
    @rxnorm_code = parse_rxnorm_code(fhir_formulary)
    @rxnorm_path = "https://mor.nlm.nih.gov/RxNav/search?searchBy=RXCUI&searchTerm=#{@rxnorm_code}"
    @formulary_id_path = "/formularies/#{@id}"
    parse_extensions(fhir_formulary)
    @plan = plansbyid[@plan_id&.to_sym]
    @plan_name = plan ? plan[:name] : "No associated plan record found"
    @plan_tierdesc = @plan[:tiers][@drug_tier&.to_sym] if @plan
  end

  #-----------------------------------------------------------------------------

  def formatted_drug_tier
    drug_tier&.split("-")&.map(&:capitalize)&.join(" ")
  end

  #-----------------------------------------------------------------------------
  private

  #-----------------------------------------------------------------------------

  # Isolates the drug name from the formulary drug resource.  If the drug name
  # is missing, it posts an error message since it is a required element.

  def parse_drug_name(fhir_formulary)
    value = ""
    if (code = fhir_formulary.code).present? && (coding = code.coding).present?
      value = display_list(coding)
    end
    return value
  end

  #-----------------------------------------------------------------------------

  # Isolates the RxNorm code from the formulary drug resource.  If the RxNorm
  # code is missing, it posts an error message since it is a required element.

  def parse_rxnorm_code(fhir_formulary)
    value = ""
    if (code = fhir_formulary.code).present? && (coding = code.coding).present?
      value = code_list(coding)
    end
    return value
  end

  #-----------------------------------------------------------------------------

  # Parses the values within the extensions defined by the formulary drug
  # resource.

  def parse_extensions(fhir_formulary)
    @coverage_restrictions = {}
    if (extensions = fhir_formulary.extension).present?
      extensions.each do |extension|
        if extension.url&.include?("DrugTierID")
          @drug_tier = parse_drug_tier(extension)
        elsif extension.url&.include?("PlanID")
          @plan_id = extension.valueString
          @plan_path = "/coverageplans/#{plan_id}"
        elsif extension.url&.include?("PriorAuthorization")
          @coverage_restrictions["prior-auth"] = "Prior Authorization" if extension.valueBoolean
        elsif extension.url&.include?("StepTherapyLimit")
          @coverage_restrictions["step-therapy"] = "Step Therapy" if extension.valueBoolean
        elsif extension.url&.include?("QuantityLimit")
          @coverage_restrictions["quantity-limit"] = "Quantity Limit" if extension.valueBoolean
        elsif extension.url&.include?("MailOrder")
          @coverage_restrictions["mail-order"] = "Mail Order" if extension.valueBoolean
        end
      end
    end
  end

  #-----------------------------------------------------------------------------

  def parse_drug_tier(extension)
    value = ""
    if (concept = extension.valueCodeableConcept).present? && (coding = concept.coding).present?
      value = code_list(coding)
    end
    return value
  end

  #-----------------------------------------------------------------------------

  def display_list(list)
    list.map { |element| element.display }.join(", ")
  end

  #-----------------------------------------------------------------------------

  # Concatenates a list of code elements.

  def code_list(list)
    list.map { |element| element.code }.join(", ")
  end
end
