################################################################################
#
# Patients Controller
#
# Copyright (c) 2020 The MITRE Corporation.  All rights reserved.
#
################################################################################

class PatientsController < ApplicationController
  def index
    puts "==>PatientsController.index"
    @patient_client = session[:patient_client]
    #redirect_to '/dashboard'
  end
end
