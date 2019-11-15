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
    cp_profile = "http://hl7.org/fhir/us/Davinci-drug-formulary/StructureDefinition/usdf-CoveragePlan"
    reply = @client.read(FHIR::List, nil, nil, cp_profile).resource
    options = reply.entry.collect{|entry| [entry.resource.title, entry.resource.identifier.first.value]}
    options.unshift(["All", ""])
    #	Build a hash of planID --> full plan URL
    #   Will need to change this to target the controller for a plan, once we build it /coverageplans/show/id, or something like that
    @@plansbyid = reply.entry.each_with_object({}) do
            | entry, planhashbyid |
             planhashbyid[entry.resource.identifier.first.value] = CoveragePlan.new(entry.resource)
    end 
    options
    rescue => exception
            options = [["N/A (Must connect first)", "-"]]
    end

end
    

