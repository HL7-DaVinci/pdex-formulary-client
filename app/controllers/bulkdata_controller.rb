require "json"
require "uri"

class BulkdataController < ApplicationController
  before_action :check_formulary_server_connection

  def index
    setexportpoll(nil)
    @request = nil
    @outputs = []
    @exportdisabled = false
    @cancelexportdisabled = true
    @pollexportdisabled = true
  end

  # Bulk Export Status Request: send a GET request to the polling URL returned
  # in the Content-Location header of the response to the kick-off request
  def pollexport
    if session[:exportpoll]
      begin
        response = RestClient.get(session[:exportpoll], { prefer: "respond-async" })
        # 200 complete with body response
        # 202 in progress with X-Progress header
        # then should hit the endpoint until a code = 200 is received
        # 500 error

        case response.code
        when 200
          results = JSON.parse(response.body, symbolize_names: true)
          @request = results[:request]
          @outputs = results[:output]
          @requiresToken = results[:requiresAccessToken]
          setexportpoll(nil)
          flash.now[:notice] = "#{response.request.url} Export Successfully Completed!"
        when 202
          results = JSON.parse(response.to_str)
          progress = response.headers["X-Progress"]
          @request = "#{response.request.url} Export request: #{progress} ... try again later"
          @outputs = []
          @requiresToken = "Pending request ... try again"
          flash.now[:notice] = "#{response.request.url} Export still in progress"
        end
      rescue => exception
        error = JSON.parse(exception.response, symbolize_names: true)
        @request = "#{session[:exportpoll]} Export Request Failed"
        @requiresToken = ""
        @outputs = []
        setexportpoll(nil)
        flash.now[:error] = error[:issue][0][:diagnostics]
      end
    else
      redirect_to bulkdata_index_path, flash: { error: "Export request not started" } and return
    end
    @exportdisabled = false
    @cancelexportdisabled = response.code == 200 ? true : false
    @pollexportdisabled = true if response.code == 200

    render :index
  end

  def cancel
    setexportpoll(nil)
    redirect_to bulkdata_index_path, flash: { error: "Export request cancelled" }
  end

  # /InsurancePlan Bulk Data Kick-off Request
  def export
    bulk_url = "#{cookies[:server_url].delete_suffix("/")}/InsurancePlan/$export"
    # response = RestClient::Request.new( :method => :get, :url => bulk_url, :prefer => "respond-async").execute
    begin
      response = RestClient.get(bulk_url, { prefer: "respond-async" })
      # should expect code=202 with Content-Location header with the absolute URL of an endpoint
      exportpollurl = response.headers[:content_location]
      setexportpoll(exportpollurl)
      @request = "#{response.request.url} successfuly requested"
      @requiresToken = ""
      @outputs = []
      flash.now[:notice] = "#{response.request.url} Export Successfully Requested"
    rescue => exception
      error = JSON.parse(exception.response, symbolize_names: true)
      @request = "#{bulk_url} Export Request Failed"
      @requiresToken = ""
      @outputs = []
      setexportpoll(nil)
      @exportdisabled = true
      @cancelexportdisabled = false
      @pollexportdisabled = false
      flash.now[:error] = error[:issue][0][:diagnostics]
    end
    render :index
  end

  #-----------------------------------------------------------------------------
  private

  def setexportpoll(url)
    if url
      @label = "ExportPoll"
    else
      @label = "Export"
    end
    session[:exportpoll] = url
  end
end
