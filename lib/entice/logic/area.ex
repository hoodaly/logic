defmodule Entice.Logic.Area do
  use Entice.Logic.Area.Maps

  # Lobby is for special client entities that represent a logged in client.
  defmap Lobby

  # Transfer is for entities that undergo a map-change.
  defmap Transfer

  defmap HeroesAscent, spawn: %Coord{x: 2017, y: -3241}
  defmap RandomArenas, spawn: %Coord{x: 3854, y: 3874}
  defmap TeamArenas,   spawn: %Coord{x: -1873, y: 352}

  def default_area, do: HeroesAscent

  @doc """
  Adds an alias for all defined maps when 'used'.
  """
  defmacro __using__(_) do
    quote do
      alias Entice.Logic.Area
      unquote(for map <- get_maps do
        quote do: alias unquote(map)
      end)
    end
  end
end
