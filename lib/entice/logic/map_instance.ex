defmodule Entice.Logic.MapInstance do
  use Entice.Logic.Attributes
  alias Entice.Entity
  alias Entice.Entity.Coordination
  alias Entice.Entity.Suicide
  alias Entice.Logic.MapInstance
  alias Entice.Logic.Item
  alias Entice.Logic.Npc
  alias Entice.Logic.MapRegistry


  defstruct(players: 0, map: nil, instance: nil)


  def register(entity, map, instance) do
    Suicide.unregister(entity) # maps will kill themselfes on their own
    Entity.put_behaviour(entity, MapInstance.Behaviour, %{map: map, instance: instance})
  end


  def unregister(entity) do
    Suicide.register(entity)
    Entity.remove_behaviour(entity, MapInstance.Behaviour)
  end


  def load_content(entity) do
    %MapInstance{map: map} = Entity.get_attribute(entity, MapInstance)
    :ok = MapInstance.add_npc(entity, "Dhuum", :dhuum, %Position{coord: map.spawn})
  end


  def add_player(entity, player_entity),
  do: Coordination.notify(entity, {:map_instance_player_add, player_entity})


  def add_npc(entity, name, model, %Position{} = position) when is_binary(name) and is_atom(model),
  do: Coordination.notify(entity, {:map_instance_npc_add, %{name: name, model: model, position: position}})

  def add_item(entity, %Item{} = item, %Position{} = position),
  do: Coordination.notify(entity, {:map_instance_item_add, %{item: item, position: position}})

  def pickup_item(entity, entity_to_pickup),
  do: Coordination.notify(entity, {:map_instance_item_pickup, %{item: entity_to_pickup}})

  def get_players(entity) do
    {:ok, %MapInstance{players: players}} = Entity.fetch_attribute(entity, MapInstance)
    players
  end

  def get_seeker(entity) do
    get_players(entity) |> Enum.filter(fn x -> Entity.has_attribute?(Entice.Logic.Seek) end)
  end


  defmodule Behaviour do
    use Entice.Entity.Behaviour
    alias Entice.Logic.Player.Appearance

    def init(%Entity{} = entity, %{map: map, instance: instance} = minst) do
      Coordination.register_observer(self(), entity)
      {:ok, entity |> put_attribute(%MapInstance{map: map, instance: instance})}
    end


    def handle_event(
        {:map_instance_player_add, player_entity},
        %Entity{attributes: %{MapInstance => %MapInstance{map: map, players: players}}} = entity) do
      Coordination.register(player_entity, entity)
      {:ok, entity |> update_attribute(MapInstance, fn(m) -> %MapInstance{m | players: players+1} end)}
    end

    def handle_event(
        {:map_instance_npc_add, %{name: name, model: model, position: position}},
        %Entity{attributes: %{MapInstance => %MapInstance{map: map}}} = entity) do
      {:ok, eid, _pid} = Npc.spawn(map, name, model, position, seeks: true)
      Coordination.register(eid, entity)
      {:ok, entity}
    end

    def handle_event(
        {:map_instance_item_add, %{item: %Item{} = item, position: position}},
        %Entity{attributes: %{MapInstance => %MapInstance{map: map} = map_inst}} = entity) do
      {:ok, eid, _pid} = Item.spawn(map_inst, item, position)
      Coordination.register(eid, entity)
      {:ok, entity}
    end

    def handle_event(
        {:map_instance_item_pickup, %{item: item}},
        %Entity{attributes: %{MapInstance => %MapInstance{map: map} = map_inst}} = entity) do
      Entity.stop(item)
      {:ok, entity}
    end

    def handle_event(
        {:entity_leave, %{attributes: %{Appearance => _}}},
        %Entity{attributes: %{MapInstance => %MapInstance{map: map, players: players}}} = entity) do
      new_entity = entity |> update_attribute(MapInstance, fn instance -> %MapInstance{instance | players: players-1} end)
      case players-1 do
        count when count <= 0 ->
          Coordination.notify_all(map, Suicide.poison_pill_message) # this is why we deactivate our suicide behaviour
          Coordination.stop_channel(map)
          {:stop_process, :normal, new_entity}
        _ -> {:ok, new_entity}
      end
    end


    def terminate(_reason, %Entity{attributes: %{MapInstance => %MapInstance{} = map_inst}} = entity) do
      MapRegistry.stop_instance(map_inst)
      {:ok, entity |> remove_attribute(MapInstance)}
    end
  end
end
