class CreateClientConnections < ActiveRecord::Migration[5.2]
  def change
    create_table :client_connections do |t|
      t.string :server_url
      t.string :client_id
      t.string :client_secret
      t.string :scope
      t.string :aud
      t.string :redirect_url, default: "http://localhost:3000/login"
    end
    add_index :client_connections, :server_url, unique: true
  end
end
