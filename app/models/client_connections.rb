class ClientConnections

    @@clients = Hash.new

    def self.set(id, url)
        begin
            client = FHIR::Client.new(url)
            client.use_r4
            FHIR::Model.client = client
            profile = "http://hl7.org/fhir/us/Davinci-drug-formulary/StructureDefinition/usdf-FormularyDrug"
            search = { parameters: { _profile: profile, _summary: "count" } }
            count = client.search(FHIR::MedicationKnowledge, search: search ).resource.total
            raise "No Formularies in server" unless count > 0
        rescue
            return nil
        end
        @@clients[id] = Hash.new
        @@clients[id][:client] = client
    end

    def self.get(id)
        @@clients[id][:client] if @@clients[id]
    end

    # sets cache if input is provided, then returns current cache value
    def self.cache(id, input = nil)
        input ? @@clients[id][:cache] = input : @@clients[id][:cache]
    end

    def self.cache_nil?(id)
        @@clients[id].nil? || @@clients[id][:cache].nil?
    end

end