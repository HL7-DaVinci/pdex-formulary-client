PRIOR_AUTH     = 1
STEP_THERAPY   = 2
QUANTITY_LIMIT = 3

CLIENT_URL = ENV.fetch("CLIENT_URL", "http://localhost:3000")

# Default server offered in the connect form. Override with FORMULARY_SERVER_URL;
# otherwise assume a local server in development and the hosted RI elsewhere.
DEFAULT_FORMULARY_SERVER = ENV.fetch("FORMULARY_SERVER_URL") do
  Rails.env.development? ? "http://localhost:8080/fhir" : "https://drug-formulary-ri.davinci.hl7.org/fhir"
end
