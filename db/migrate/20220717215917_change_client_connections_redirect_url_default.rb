class ChangeClientConnectionsRedirectUrlDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default :client_connections, :redirect_url, from: "http://localhost:3000/login", to: "#{CLIENT_URL}/login"
  end
end
