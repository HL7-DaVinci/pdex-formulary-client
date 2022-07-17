class ClientConnections < ApplicationRecord
  @clients = Hash.new

  before_save :default_scope, :default_aud, :format_server_url, :format_open_server_url, :default_redirect_url
  # Validations
  validates_presence_of :server_url, :client_id, :client_secret
  validates_uniqueness_of :server_url

  def redirect_url
    @redirect_url = "http://localhost:3000/login"
  end

  # ------------------ Class Methods -----------------------------------

  # Set the fhir client connection to the fhir server
  # @return FHIR::Client instance or nil if connection not established
  def self.set(id, url)
    client = nil
    begin
      puts "ClientConnections:set  (#{id}, #{url})"
      client = FHIR::Client.new(url)
      client.use_r4
      client.additional_headers = { "Accept-Encoding" => "identity" }  #
      FHIR::Model.client = client
      raise "Unable to retrieve capability statement" if client.capability_statement.nil?
    rescue => error
      puts "ClientConnections:set  -- returning nil -- #{error.message}"
      return nil
    end
    @clients[id] = Hash.new
    prune(id)
    client
    # @clients[id][:client] = client
  end

  # Set and save open and authenticated fhir client instances.
  # @return true if open or authenticated fhir client instance successfully created, false otherwise
  def self.set_open_and_auth(id, secure_server_url, open_server_url)
    if (secure_server_url.present? && open_server_url.nil?)
      client = set(id, secure_server_url)
      @clients[id][:client] = @clients[id][:auth_client] = client
    elsif (open_server_url.present? && secure_server_url.nil?)
      client = set(id, open_server_url)
      @clients[id][:client] = client
    elsif (open_server_url.present? && secure_server_url.present?)
      auth = set(id, secure_server_url)
      @clients[id][:auth_client] = auth
      open_client = set(id, open_server_url)
      @clients[id][:client] = open_client
    end
    (@clients[id][:auth_client] || @clients[id][:client]).present?
  end

  # Retrieves the secure fhir client if secured connection was established
  def self.get_secure(id)
    return nil unless @clients[id]
    prune(id)
    @clients[id][:auth_client]
  end

  # Retrieves the fhir client if connection to the server was established
  def self.get(id)
    return nil unless @clients[id]
    prune(id)
    @clients[id][:client]
  end

  # Delete the authenticated client
  def self.delete_auth(id)
    @clients[id].delete(:auth_client) if @clients[id]
  end

  # Set client to use Bearer authenticationif connection is established
  def self.set_bearer_token(id, token)
    if client = self.get_secure(id)
      client.set_bearer_token(token)
      @clients[id][:auth_client] = client
    end
  end

  # sets cache if input is provided, then returns current cache value
  def self.cache(id, input = nil)
    prune(id)
    input ? @clients[id][:cache] = input : @clients[id][:cache]
  end

  def self.cache_nil?(id)
    prune(id)
    @clients[id].nil? || @clients[id][:cache].nil?
  end

  def self.prune(protectID = nil)
    puts "ClientConnect:prune (protectID = #{protectID} clients = #{@clients.keys}"
    @clients.each { |key, value| puts "key: ##{key}  lastused: #{value[:lastUsed]}" }
    @clients[protectID][:lastUsed] = Time.now if protectID && @clients[protectID]
    safeHours = 5
    @clients.delete_if { |id, connection| (Time.now - connection[:lastUsed]) > (safeHours * 60 * 60) }
    puts "After #{@clients.keys}"
    @clients.each { |key, value| puts "key: ##{key}  lastused: #{value[:lastUsed]}" }
  rescue => exception
    puts "failure in Client:Connection.prune"
  end

  private

  def format_server_url
    self.server_url = self.server_url.delete_suffix("/").delete_suffix("/metadata")
  end

  def format_open_server_url
    self.open_server_url = self.open_server_url&.delete_suffix("/")&.delete_suffix("/metadata")
  end

  def default_redirect_url
    self.redirect_url = "#{CLIENT_URL}/login"
  end

  def default_scope
    self.scope ||= "launch/patient openid fhirUser offline_access user/*.read patient/*.read"
  end

  def default_aud
    self.aud ||= self.server_url
  end
end
