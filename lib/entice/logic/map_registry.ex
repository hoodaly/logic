defmodule Entice.Logic.MapRegistry do
  @doc """
  Stores all the instances for each map.
  Its state is in the following format: %{map=>entity_id}
  """
  alias Entice.Entity
  alias Entice.Entity.Suicide
  alias Entice.Logic.{MapInstance}


  def start_link,
  do: Agent.start_link(fn -> %{} end, name: __MODULE__)


  @doc "Get or create an instance entity for a specific map"
  def get_or_create_instance(map, inst) when is_atom(map) do
    Agent.get_and_update(__MODULE__, fn state ->
      case fetch_active(map, inst, state) do
        {:ok, entity_id} -> {entity_id, state}
        :error ->
          with {:ok, entity_id, _pid} <- Entity.start,
               :ok                    <- MapInstance.register(entity_id, map, inst),
               :ok                    <- MapInstance.load_content(entity_id),
               new_state              =  Map.put(state, map_key(map, inst), entity_id),
               do: {entity_id, new_state}
      end
    end)
  end


  @doc "Stops an instance if not already stopped, effectively killing the entity."
  def stop_instance(%MapInstance{map: map, instance: inst}), do: stop_instance(map, inst)
  def stop_instance(map, inst) when is_atom(map) do
    Agent.cast(__MODULE__, fn state ->
      with {:ok, entity_id} <- Map.fetch(state, map_key(map, inst)),
           :ok              <- MapInstance.unregister(entity_id),
           :ok              <- Suicide.poison_pill(entity_id),
           do: :ok
      state |> Map.delete(map)
    end)
  end


  defp fetch_active(map, inst, state) when is_atom(map) do
    case Map.fetch(state, map_key(map, inst)) do
      {:ok, entity_id} ->
        if Entity.exists?(entity_id), do: {:ok, entity_id},
                                    else: :error
      _ -> :error
    end
  end

  defp map_key(map, inst) when is_atom(map),
  do: String.to_atom(to_string(map) <> ":" <> inst)
end
