module SessionsHelper
  # Get fhir client in use
  def client
    @client = ClientConnections.get(session.id.public_id)
  end

  # Get authenticated fhir client in use
  def auth_client
    @client = ClientConnections.get_secure(session.id.public_id)
  end

  # Client credentials used to authenticate with fhir server
  def credentials_in_use(client_connections_obj = nil)
    session[:credentials] = client_connections_obj if client_connections_obj
  end

  # Get the authentication metadata
  def authentication_metadata
    auth_client&.get_oauth2_metadata_from_conformance
  end

  # Check if connected to server
  def server_connected?
    !!client
  end

  # Check if client is authenticated
  def client_is_authenticated?
    !!auth_client
  end

  # Get Basic authentication value
  def basic_auth(client_id, client_secret)
    token = Base64.strict_encode64("#{client_id}:#{client_secret}")
    "Basic #{token}"
  end
end
