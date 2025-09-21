defmodule GameOfLifeWeb.PageController do
  use GameOfLifeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
