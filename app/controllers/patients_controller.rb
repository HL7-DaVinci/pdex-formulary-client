################################################################################
#
# Patients Controller
#
# Copyright (c) 2020 The MITRE Corporation.  All rights reserved.
#
################################################################################

class PatientsController < ApplicationController
  before_action :check_formulary_server_connection
  def index
    puts '==>PatientsController.index'
    @client = session[:auth_client]
  end
end
