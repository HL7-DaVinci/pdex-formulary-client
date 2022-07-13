class ClientConnections < ApplicationRecord
  @clients = Hash.new
  @@capability_statement

  before_save :default_scope, :default_aud, :format_server_url
  # Validations
  validates_presence_of :server_url, :client_id, :client_secret
  validates_uniqueness_of :server_url

  def redirect_url
    @redirect_url = "http://localhost:3000/login"
  end

  # ------------------ Class Methods -----------------------------------

  # Set the fhir client connection to the fhir server
  def self.set(id, url)
    begin
      puts "ClientConnections:set  (#{id}, #{url})"
      client = FHIR::Client.new(url)
      client.use_r4
      client.additional_headers = { "Accept-Encoding" => "identity" }  #
      FHIR::Model.client = client
      @@capability_statement = client.capability_statement
      raise "Unable to retrieve capability statement" if @@capability_statement.nil?
    rescue => error
      puts "ClientConnections:set  -- returning nil -- #{error.message}"
      return nil
    end
    @clients[id] = Hash.new
    prune(id)
    @clients[id][:client] = client
  end

  # Retrieves the fhir client if connection to the server is established
  def self.get(id)
    return nil unless @clients[id]
    prune(id)
    @clients[id][:client]
  end

  # Set client to use Bearer authenticationif connection is established
  def self.set_bearer_token(id, token)
    if client = self.get(id)
      client.set_bearer_token(token)
      @clients[id][:client] = client
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

  # Return the server capability_statement
  def self.capability_statement
    @@capability_statement
  end

  private

  def format_server_url
    self.server_url = self.server_url.delete_suffix("/").delete_suffix("/metadata")
  end

  def default_scope
    self.scope ||= "launch/patient openid fhirUser offline_access user/*.read patient/*.read"
  end

  def default_aud
    self.aud ||= self.server_url
  end
end
