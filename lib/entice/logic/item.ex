defmodule Entice.Logic.Item do
  use Entice.Logic.Map
  alias Entice.Entity
  alias Entice.Logic.Item
  alias Entice.Logic.Player.{Name, Position}

  defstruct(
    name: "",
    type: "",
    model: "",
    color: [],
    flags: [],
    stats: [],
    location: nil
  )


  def spawn(map_instance, %Item{} = item, %Position{} = position, opts \\ []) do
    {:ok, id, pid} = Entity.start()
    Item.register(id, map_instance, item, position)
    {:ok, id, pid}
  end


  def register(entity, map, %Item{name: name} = item, %Position{} = position) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.put(Name,     %Name{name: name})
      |> Map.put(Position, position)
      |> Map.put(Item,     item)
    end)
  end


  def unregister(entity) do
    entity |> Entity.attribute_transaction(fn (attrs) ->
      attrs
      |> Map.delete(Name)
      |> Map.delete(Position)
      |> Map.delete(Item)
    end)
  end


  def attributes(entity),
  do: Entity.take_attributes(entity, [Name, Position, Item])
end
