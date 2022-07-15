################################################################################
#
# Patients Controller
#
# Copyright (c) 2022 The MITRE Corporation.  All rights reserved.
#
################################################################################

class PatientsController < ApplicationController
  def new
    auth_client
    session[:credentials] = nil if @client.nil?
    # @credentials = session[:credentials]
  end

  def create
    credentials = ClientConnections.find_by(server_url: params[:server_url].delete_suffix("/"))
    credentials = ClientConnections.new(cred_params) if (params[:client_id] && params[:client_secret]).present?

    connect_to_formulary_server(params[:server_url], credentials&.open_server_url)
    if @connection.present?
      flash.now[:error] = @connection.delete(:error)
      render :new
    else
      if credentials
        credentials_in_use(credentials)
        get_plansbyid if server_connected?
        redirect_to launch_path
      else
        flash.now[:alert] = "No credentials found. Please provide the server url, client id, and client secret to connect."
        @credentials = ClientConnections.new(cred_params)
        render :new
      end
    end
  end

  private

  def cred_params
    params.permit(:server_url, :client_id, :client_secret, :scope, :aud)
  end
end
