class AddOpenServerUrlToClientConnections < ActiveRecord::Migration[5.2]
  def change
    add_column :client_connections, :open_server_url, :string
  end
end
