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
        @@clients[id] = client
    end

    def self.get(id)
        @@clients[id]
    end

end