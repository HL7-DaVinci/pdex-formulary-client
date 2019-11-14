################################################################################
#
# Application Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class ApplicationController < ActionController::Base

def self.plansbyid
    @@plansbyid
end

private
def coverage_plans
    begin
        cp_profile = "http://hl7.org/fhir/us/Davinci-drug-formulary/StructureDefinition/usdf-CoveragePlan"
        reply = @client.read(FHIR::List, nil, nil, cp_profile).resource
        options = reply.entry.collect{|entry| [entry.resource.title, entry.resource.identifier.first.value]}
        options.unshift(["All", ""])
    #	Build a hash of planID --> full plan URL
    #   Will need to change this to target the controller for a plan, once we build it /coverageplans/show/id, or something like that
        @@plansbyid = reply.entry.each_with_object({}) do
            | entry, planhashbyid |
             planhashbyid[entry.resource.identifier.first.value] = 
            {
                :url => entry.fullUrl,
                :name => entry.resource.title, 
            } 
        end 
        reply.entry.each do
                | entry |
                 @@plansbyid[entry.resource.identifier.first.value][:tiers] = process_tiers( entry )
        end
        rescue => exception
            options = [["N/A (Must connect first)", "-"]]
    end
    options
end


def process_tiers(entry)
        extensions = entry.resource.extension
        tiers = {}
		if extensions.present?
				extensions.each do |extension|
                    if extension.url.include?("DrugTierDefinition")
                        tiername = ""
                        mailorder= false
                        costshares = {}
                        extension.extension.each do |drugtier_extension|
                            if drugtier_extension.url.include?("DrugTierID")
                                tiername = drugtier_extension.valueCodeableConcept.coding[0].code
                            elsif drugtier_extension.url.include?("MailOrder")
                                mailorder = drugtier_extension.valueBoolean
                            elsif drugtier_extension.url.include?("CostSharing")
                                costshare = {}
                                copay = 0
                                coinsurancerate = 0
                                copayoption = ""
                                coinsuranceoption = ""
                                pharmacytype = ""
                                drugtier_extension.extension.each do |costshare_extension|
                                    if costshare_extension.url.include?("PharmacyType")
                                        pharmacytype = costshare_extension.valueCodeableConcept.coding[0].code
                                    elsif costshare_extension.url.include?("CopayAmount")
                                        copay = costshare_extension.valueMoney.value
                                    elsif costshare_extension.url.include?("CoInsuranceRate")
                                        coinsurancerate = costshare_extension.value
                                    elsif costshare_extension.url.include?("CoinsuranceOption")
                                        coinsuranceoption = costshare_extension.valueCodeableConcept.coding[0].code
                                    elsif costshare_extension.url.include?("CopayOption")
                                        copayoption = costshare_extension.valueCodeableConcept.coding[0].code
                                    else
                                        binding.pry 
                                    end
                                end 
                                    costshare = {:pharmacytype => pharmacytype,
                                                :copay => copay,
                                                :coinsurancerate => coinsurancerate,
                                                :copayoption => copayoption ,
                                                :coinsuranceoption => coinsuranceoption}

                                costshares[pharmacytype] = costshare
                            end 

                        end 
                    tiers[tiername] = {:mailorder => mailorder, :costshares => costshares}
                    end
                end
            end
            return tiers 
        end
   
    end

