################################################################################
#
# Application Controller
#
# Copyright (c) 2019 The MITRE Corporation.  All rights reserved.
#
################################################################################

class ApplicationController < ActionController::Base

@@plansbyid = {}

def self.plansbyid
    @@plansbyid
end

private
def coverage_plans
    # Read all of the coverage plans from the server
    cp_profile = "http://hl7.org/fhir/us/Davinci-drug-formulary/StructureDefinition/usdf-CoveragePlan"
    reply = @client.read(FHIR::List, nil, nil, cp_profile).resource
    @plansbyid  = build_coverage_plans (reply)
    @@plansbyid = @plansbyid 
    options = build_coverage_plan_options(reply)
    rescue => exception
            options = [["N/A (Must connect first)", "-"]]
    end

end
    
def build_coverage_plan_options(fhir_list_reply)
    options = fhir_list_reply.entry.collect{|entry| [entry.resource.title, entry.resource.identifier.first.value]}
    options.unshift(["All", ""])
end

def build_coverage_plans (fhir_list_reply)
    fhir_list_reply.entry.each_with_object({}) do
        | entry, planhashbyid |
         planhashbyid[entry.resource.identifier.first.value] = CoveragePlan.new(entry.resource)
    end
end
