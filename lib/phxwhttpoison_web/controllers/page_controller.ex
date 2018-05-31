defmodule PhxwhttpoisonWeb.PageController do
  use PhxwhttpoisonWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
