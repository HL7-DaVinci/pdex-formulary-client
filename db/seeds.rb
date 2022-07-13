# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

ClientConnections.destroy_all

ClientConnections.create!([{
  server_url: "https://davinci-drug-formulary-ri.logicahealth.org/fhir",
  client_id: "b0c46635-c0b4-448c-a8b9-9bd282d2e05a",
  client_secret: "bUYbEj5wpazS8Xv1jyruFKpuXa24OGn9MHuZ3ygKexaI5mhKUIzVEBvbv2uggVf1cW6kYD3cgTbCIGK3kjiMcmJq3OG9bn85Fh2x7JKYgy7Jwagdzs0qufgkhPGDvEoVpImpA4clIhfwn58qoTrfHx86ooWLWJeQh4s0StEMqoxLqboywr8u11qmMHd1xwBLehGXUbqpEBlkelBHDWaiCjkhwZeRe4nVu4o8wSAbPQIECQcTjqYBUrBjHlMx5vXU",
  scope: "launch/patient openid fhirUser offline_access user/*.read patient/*.read",
},
                           {
  server_url: "https://api-dmdh-t31.safhir.io/v1/api/secure-formulary",
  client_id: "5bc53afe-635c-4fd4-9b46-44639214e51d",
  client_secret: "HK-8Q~Tenf8HWejmLvTsPaoMW3DULLJX2U7zua4F",
  scope: "launch/patient fhirUser openid offline_access patient/List.read patient/MedicationKnowledge.read user/List.read user/MedicationKnowledge.read user/ExplanationOfBenefit.read user/Coverage.read user/Location.read user/Organization.read user/Patient.read patient/ExplanationOfBenefit.read patient/Coverage.read patient/Location.read patient/Organization.read patient/Patient.read",
  aud: "https://api-dmdh-t31.safhir.io/v1",
}])

p "Saved #{ClientConnections.count} client credentials."
