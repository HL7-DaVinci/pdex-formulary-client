class ClientConnections
  @clients = {}

  def self.set(id, url)
    begin
      puts "ClientConnections:set  (#{id}, #{url})"
      client = FHIR::Client.new(url)
      client.use_r4
      client.additional_headers = { 'Accept-Encoding' => 'identity' }
      FHIR::Model.client = client
      search = { parameters: { _summary: 'count' } }
      result = client.search(FHIR::MedicationKnowledge, search: search)
      if result.response[:code] != 200
        err = JSON.parse(result.response[:body])['issue']
        err.present? ? (raise err.first['diagnostics']) : (raise 'Invalid FHIR server: Please provide a valid FHIR server')
      end
      err = 'Connection failed: Ensure provided url points to a valid FHIR server that holds at least one Formulary'
      raise err unless result.resource.total > 0
    rescue StandardError => e
      return e.message
    end
    @clients[id] = {}
    prune(id)
    @clients[id][:client] = client
  end

  def self.get(id)
    return nil unless @clients[id]

    prune(id)
    @clients[id][:client]
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
    @clients.delete_if { |_id, connection| (Time.now - connection[:lastUsed]) > (safeHours * 60 * 60) }
    puts "After #{@clients.keys}"
    @clients.each { |key, value| puts "key: ##{key}  lastused: #{value[:lastUsed]}" }
  rescue StandardError => e
    puts 'failure in Client:Connection.prune'
  end
end
