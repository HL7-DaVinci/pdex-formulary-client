namespace :clientcredentials do
  desc "Seeds client credentials"
  task seed_credentials: :environment do
    ClientConnections.create!([{
      server_url: "https://davinci-drug-formulary-ri.logicahealth.org/fhir",
      client_id: "1e26250f-5540-4c10-a47c-78594fcd33e0",
      client_secret: "69VTDGb27qpsOWZSrE0p8qnn33dE74pkFxBImkCldtXANkwTqaZdpIkOxd3A6qEwo6EMBQvJgE7ChDAm7ao9510A4jfYhWivn5NNrySZ45vRgyP8dHGkhoyMF6MToMGvbSChC6llKO8rcu1GqNaUyQJZ4P0MMFWaOQsFNzoC6QtTgZp0PD6KUeGycYySc3pJOHrZPucNRYe77vG9KyKJj0LCv9aIFuX6G1WzjOcS1WfA5xyHrXjoaNBaaD5dclqq",
      scope: "launch/patient openid fhirUser offline_access user/*.read patient/*.read",
    },
                               {
      server_url: "https://api-dmdh-t31.safhir.io/v1/api/secure-formulary",
      client_id: "5bc53afe-635c-4fd4-9b46-44639214e51d",
      client_secret: "HK-8Q~Tenf8HWejmLvTsPaoMW3DULLJX2U7zua4F",
      scope: "launch/patient fhirUser openid offline_access patient/List.read patient/MedicationKnowledge.read user/List.read user/MedicationKnowledge.read user/ExplanationOfBenefit.read user/Coverage.read user/Location.read user/Organization.read user/Patient.read patient/ExplanationOfBenefit.read patient/Coverage.read patient/Location.read patient/Organization.read patient/Patient.read",
      aud: "https://api-dmdh-t31.safhir.io/v1",
    }])

    p "Created #{ClientConnections.count} client connection credentials"
  end
end
