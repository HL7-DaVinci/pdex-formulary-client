################################################################################
#
# PayerPlan Model => PayerInsurancePlan profile
#
# Copyright (c) 2021 The MITRE Corporation.  All rights reserved.
#
################################################################################

class PayerPlan < Resource
  include ActiveModel::Model

  attr_accessor :id, :name, :planid, :period, :contacts, :coverage_area_ids, :formularies_ids, :plans

  def initialize(fhir_payerplan)
    @name = fhir_payerplan.name
    @id = fhir_payerplan.id
    @planid = fhir_payerplan.identifier&.first&.value
    @period = fhir_payerplan.period
    @coverage_area_ids = parse_coverage_area_ids(fhir_payerplan.coverageArea)
    @contacts = parse_contacts(fhir_payerplan.contact)
    @formularies_ids = parse_formularies_ids(fhir_payerplan.coverage)
    @plans = parse_plans(fhir_payerplan.plan)
  end

  #-----------------------------------------------------------------------------

  def parse_plans(fhir_plans = [])
    plans = []
    fhir_plans.each do |fhir_plan|
      plan = {}
      tiers = {}
      type = coding_to_string(fhir_plan.type&.coding)

      fhir_plan.specificCost&.each do |cost|
        pharmacy_type = coding_to_string(cost.category&.coding).downcase

        cost.benefit&.each do |benefit|
          tier_name = coding_to_string(benefit.type&.coding).downcase
          costshare = {}
          benefit.cost&.each do |share|
            share_type = coding_to_string(share.type&.coding)
            value = share.value&.code == "%" ? "#{"%d" % (share.value&.value)}%" : "$#{"%.2f" % share.value&.value}"
            option = share.qualifiers&.map { |e| coding_to_string(e.coding) }&.join(",")

            if share_type.downcase == "copay"
              costshare[:copay] = value
              costshare[:copay_option] = option
            else
              costshare[:coinsurance] = value
              costshare[:coinsurance_option] = option
            end
          end

          if tiers[tier_name.to_sym]
            tiers[tier_name.to_sym][pharmacy_type.to_sym] = costshare
          else
            tiers[tier_name.to_sym] = { pharmacy_type.to_sym => costshare }
          end
        end
      end

      plan[:type] = type
      plan[:tiers] = tiers
      plans << plan
    end
    plans
  end

  #-----------------------------------------------------------------------------

  def parse_coverage_area_ids(coverage_areas = [])
    coverage_areas.map { |location| location.reference.split("/").last }
  end

  #-----------------------------------------------------------------------------

  def parse_formularies_ids(formularies = [])
    formularies.map(&:extension)&.flatten&.map { |formulary| formulary.valueReference.reference.split("/").last }
  end

  #-----------------------------------------------------------------------------

  def parse_contacts(fhir_payerplan_contact = [])
    contacts = {}
    fhir_payerplan_contact.each do |contact_info|
      telecom = {}
      contact_info.telecom&.each do |type|
        telecom[type.system] = type.value
      end
      contact_name = contact_info&.name&.text || coding_to_string(contact_info.purpose&.coding)
      contacts[contact_name] = telecom
    end

    return contacts
  end

  #-----------------------------------------------------------------------------
end
