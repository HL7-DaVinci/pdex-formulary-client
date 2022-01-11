################################################################################
#
# Auth Helper
#
# Copyright (c) 2022 The MITRE Corporation.  All rights reserved.
#
################################################################################
# Helpers to authenticate with a FHIR Server
module AuthHelper
  # --------------------------------------------------------
  # JWT
  def encode_token(payload, rsa_key, header)
    JWT.encode(payload, rsa_key, "RS256", header)
  end

  # --------------------------------------------------------
  # X.509 certificate
  def get_certificate
    certificate = OpenSSL::X509::Certificate.new(File.read("app/certificates/udap-sandbox-mitre.crt"))
    Base64.strict_encode64(certificate.to_der)
    # cert = OpenSSL::X509::Certificate.new
    # cert.version = 2
    # cert.serial = Random.rand(65534) + 1  # Randomly generated for better security aspect
    # cert.subject = cert.issuer = OpenSSL::X509::Name.parse("/CN=localhost CA") # "self-signed"
    # cert.public_key = rsa_key.public_key
    # cert.not_before = Time.now
    # cert.not_after = cert.not_before + 2 * 365 * 24 * 60 * 60 # 2 years validity
    # ef = OpenSSL::X509::ExtensionFactory.new
    # ef.subject_certificate = cert
    # ef.issuer_certificate = cert
    # cert.add_extension(ef.create_extension("basicConstraints", "CA:TRUE", true))
    # cert.add_extension(ef.create_extension("keyUsage", "keyCertSign, digitalSignature, cRLSign", true))
    # # cert.add_extension(ef.create_extension("keyUsage", "digitalSignature", true))
    # cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
    # cert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))
    # cert.add_extension(ef.create_extension("subjectAltName", "DNS:#{root_url}"))
    # cert.sign(rsa_key, OpenSSL::Digest.new("SHA256"))
    # Base64.strict_encode64(cert.to_der)
  end

  # --------------------------------------------------------
  def get_registration_claims(rsa_key)
    time = Time.now.to_i
    claims_obj = {
      "iss" => "https://test.healthtogo.me/udap-sandbox/mitre",
      "sub" => "https://test.healthtogo.me/udap-sandbox/mitre",
      "aud" => session[:registration_url],
      "exp" => time + 300,
      "iat" => time,
      "jti" => SecureRandom.hex,
      "client_name" => "PDEX Formulary Client",
      "redirect_uris" => [login_url],
      "contacts" => ["mailto:vfotso@mitre.org"],
      "grant_types" => ["authorization_code", "refresh_token"],
      "response_types" => ["code"],
      "token_endpoint_auth_method" => "private_key_jwt",
      "scope" => "user/*.read patient/*.read",
    }
    header = {
      "alg" => "RS256",
      "x5c" => [get_certificate()],
    }
    # byebug
    encode_token(claims_obj, rsa_key, header)
  end

  # --------------------------------------------------------
  def get_authentication_claims(rsa_key)
    time = Time.now.to_i
    claims_obj = {
      "iss" => "https://test.healthtogo.me/udap-sandbox/mitre",
      "sub" => session[:client_id],
      "aud" => session[:token_url],
      "exp" => time + 300,
      "iat" => time,
      "jti" => SecureRandom.hex
    }
    header = {
      "alg" => "RS256",
      "x5c" => [get_certificate()],
    }
    encode_token(claims_obj, rsa_key, header)
  end

  # --------------------------------------------------------
  # Check if server is an auth server
  def is_auth_server?(request_result)
    return false if request_result.nil?
    auth = !!request_result["rest"]&.first&.has_key?("security")
    if auth
      session[:auth_url] = request_result["rest"][0]["security"]["extension"][0]["extension"].select { |e| e["url"] == "authorize" }[0]["valueUri"]
      session[:token_url] = request_result["rest"][0]["security"]["extension"][0]["extension"].select { |e| e["url"] == "token" }[0]["valueUri"]
    end
    session[:is_auth_server?] = auth
  end

  # --------------------------------------------------------
  # Server auth url to redirect to for smart authorization
  def set_server_auth_url
    # for Onyx     scope = "launch/patient openid fhirUser offline_access user/ExplanationOfBenefit.read user/Coverage.read user/Organization.read user/Patient.read user/Practitioner.read patient/ExplanationOfBenefit.read patient/Coverage.read patient/Organization.read patient/Patient.read patient/Practitioner.read"
    # scope = "launch/patient openid fhirUser offline_access user/*.read patient/*.read"
    scope = "launch/patient openid fhirUser offline_access patient/*.read"
    scope = scope.gsub(" ", "%20")
    scope = scope.gsub("/", "%2F")
    server_auth_url = session[:auth_url] +
                      "?response_type=code" +
                      "&redirect_uri=" + login_url +
                      "&aud=" + session[:iss_url] +
                      "&state=98wrghuwuogerg97" +
                      "&scope=" + scope +
                      "&client_id=" + session[:client_id]
  end

  # --------------------------------------------------------
end
