class ClientConnections

    @@clients = Hash.new

    def self.set(id, url)
        begin
            client = FHIR::Client.new(url)
            client.use_r4
        rescue
            return nil
        end
        @@clients[id] = client
    end

    def self.get(id)
        @@clients[id]
    end

end