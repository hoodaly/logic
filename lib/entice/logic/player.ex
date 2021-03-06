defmodule Entice.Logic.Player do
  @moduledoc """
  Responsible for the basic player stats.
  """
  alias Entice.Entity
  alias Geom.Shape.Vector2D


  defmodule Name, do: defstruct(
    name: "Unknown Entity")

  defmodule Position, do: defstruct(
    coord: %Vector2D{},
    plane: 1)

  defmodule Appearance, do: defstruct(
    profession: 1,
    campaign: 0,
    sex: 1,
    height: 0,
    skin_color: 3,
    hair_color: 0,
    hairstyle: 7,
    face: 30)

  defmodule Level, do: defstruct(
    level: 20)

  @doc "Prepares a single, simple player"
  def register(entity, map, name \\ "Unkown Entity", appearance \\ %Appearance{}) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.put(Name, %Name{name: name})
      |> Map.put(Position, %Position{coord: map.spawn})
      |> Map.put(Appearance, appearance)
      |> Map.put(Level, %Level{level: 20})
    end)
  end


  @doc "Removes all player attributes from the entity"
  def unregister(entity) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.delete(Name)
      |> Map.delete(Position)
      |> Map.delete(Appearance)
      |> Map.delete(Level)
    end)
  end


  @doc "Returns all player related attributes as an attribute map"
  def attributes(entity),
  do: Entity.take_attributes(entity, [Name, Position, Appearance, Level])


  def set_appearance(entity, %Appearance{} = new_appear),
  do: entity |> Entity.put_attribute(new_appear)
end
