################################################################################
#
# Bulk Publish Controller
#
# Displays the server's $bulk-publish manifest (FHIR Bulk Data IG, current
# build) with links to the published ndjson files and a short preview of
# each file's content.
#
################################################################################

require "net/http"
require "json"
require "resolv"
require "ipaddr"

class BulkPublishController < ApplicationController
  before_action :check_formulary_server_connection

  PREVIEW_LINES = 5
  # Hard cap on bytes read while collecting preview lines, so one huge
  # ndjson line cannot pull an entire large file into memory. Binary
  # resources can exceed 1MB per line, so leave generous headroom.
  PREVIEW_MAX_BYTES = 5_000_000
  # When not even one complete line fits the cap, show this much raw text
  TRUNCATED_PREVIEW_BYTES = 5_000

  # GET /bulk-publish

  def index
    base_url = ClientConnections.url(session.id.public_id).to_s
    @manifest_url = "#{base_url.chomp("/")}/$bulk-publish"
    response = http_get(@manifest_url)

    if response.is_a?(Net::HTTPSuccess)
      @manifest = JSON.parse(response.body)
      # The preview action may only fetch URLs listed in this manifest.
      session[:bulk_publish_urls] = @manifest["output"].to_a.collect { |output| output["url"] }
    else
      @error = "The server returned HTTP #{response.code} for $bulk-publish. " \
               "It may not implement the bulk publish operation."
    end
  rescue JSON::ParserError
    @error = "The server's $bulk-publish response was not valid JSON."
  rescue StandardError => exception
    @error = "Could not fetch the manifest: #{exception.message}"
  end

  #-----------------------------------------------------------------------------

  # GET /bulk-publish/preview?url=...
  #
  # Renders the first few lines of one of the manifest's ndjson files inside
  # a turbo frame on the index page.

  def preview
    @url = params[:url].to_s
    # Reject URLs that were not listed in the manifest we fetched, so this
    # endpoint cannot be used to proxy requests to arbitrary hosts.
    unless Array(session[:bulk_publish_urls]).include?(@url)
      render plain: "URL is not part of the current manifest", status: :forbidden
      return
    end

    @type = params[:type]
    @lines = fetch_ndjson_lines(@url)
    render layout: false
  rescue StandardError => exception
    @preview_error = exception.message
    render layout: false
  end

  #-----------------------------------------------------------------------------
  private

  #-----------------------------------------------------------------------------

  # Ranges that are never legitimate FHIR data hosts. Loopback and private
  # ranges stay allowed on purpose: pointing this client at a local or
  # intra-network FHIR server is its primary use case.
  FORBIDDEN_RANGES = [
    IPAddr.new("169.254.0.0/16"),   # link-local, includes cloud metadata endpoints
    IPAddr.new("fe80::/10"),
    IPAddr.new("0.0.0.0/32"),
    IPAddr.new("::/128"),
  ].freeze

  def assert_fetchable!(uri)
    raise "Only http and https URLs can be fetched" unless %w[http https].include?(uri.scheme)

    addresses = Resolv.getaddresses(uri.host.to_s)
    raise "Could not resolve host #{uri.host}" if addresses.empty?

    addresses.each do |address|
      ip = IPAddr.new(address)
      raise "Refusing to fetch a link-local address" if FORBIDDEN_RANGES.any? { |range| range.include?(ip) }
    end
  end

  #-----------------------------------------------------------------------------

  def http_get(url)
    uri = URI.parse(url)
    assert_fetchable!(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                    open_timeout: 5, read_timeout: 10) do |http|
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      http.request(request)
    end
  end

  #-----------------------------------------------------------------------------

  # Streams the ndjson file and stops reading as soon as enough lines (or
  # bytes) have arrived, then pretty-prints each complete line.

  def fetch_ndjson_lines(url)
    uri = URI.parse(url)
    assert_fetchable!(uri)
    buffer = +""

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                    open_timeout: 5, read_timeout: 15) do |http|
      catch(:enough) do
        http.request(Net::HTTP::Get.new(uri)) do |response|
          raise "HTTP #{response.code} while fetching the file" unless response.is_a?(Net::HTTPSuccess)

          response.read_body do |chunk|
            buffer << chunk
            throw :enough if buffer.count("\n") >= PREVIEW_LINES || buffer.bytesize > PREVIEW_MAX_BYTES
          end
        end
      end
    end

    complete_lines = buffer.lines.select { |line| line.end_with?("\n") }

    # A single entry can exceed the byte cap (large Binary resources); fall
    # back to a raw snippet of the first entry instead of showing nothing.
    if complete_lines.empty?
      @preview_note = "The first entry is larger than the preview limit; showing the beginning of it."
      return [buffer.byteslice(0, TRUNCATED_PREVIEW_BYTES).to_s.scrub + " ..."]
    end

    # Raw JSON lines; the browser renders them as collapsible trees
    complete_lines.first(PREVIEW_LINES).collect(&:chomp)
  end
end
