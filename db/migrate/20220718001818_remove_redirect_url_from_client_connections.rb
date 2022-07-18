class RemoveRedirectUrlFromClientConnections < ActiveRecord::Migration[5.2]
  def change
    remove_column :client_connections, :redirect_url, :string
  end
end
