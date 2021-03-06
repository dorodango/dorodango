defmodule Doro.Entity do
  alias Doro.Entity
  alias Doro.World

  defstruct proto: nil,
            id: nil,
            behaviors: %{},
            name: nil,
            name_tokens: nil,
            src: nil,
            props: %{}

  def execute_behaviors(ctx) do
    Enum.reduce(Entity.behaviors(ctx.object), ctx, fn behavior, acc ->
      behavior.handle(acc.verb, acc)
    end)
  end

  @doc "Creates an entity"
  def create(prototype_id, props, naming_fn, id \\ nil) do
    prototype = Doro.World.get_entity(prototype_id)

    %{
      id: id || generate_id(prototype_id),
      name: naming_fn.(prototype),
      proto: prototype_id,
      props: props
    }
    |> preprocess_name()
    |> (&struct(Entity, &1)).()
  end

  @doc "Creates an entity from raw args"
  def create(entity = %{id: _, name: _}) do
    entity
    |> preprocess_name()
    |> (&struct(Entity, &1)).()
  end

  @doc "Returns the first behavior that can handle this verb in this context"
  def first_responder(entity = %Entity{}, ctx = %Doro.Context{verb: verb}) do
    behaviors(entity)
    |> Map.keys()
    |> Enum.find(& &1.responds_to?(verb, %{ctx | object: entity}))
  end

  def behaviors(%Entity{behaviors: behaviors}), do: behaviors

  def own_behaviors(%Entity{behaviors: behaviors}) do
    behaviors
    |> Enum.filter(&match?({_key, %{own: true}}, &1))
    |> Enum.into(%{})
  end

  def has_behavior?(entity, behavior) do
    match?(%{^behavior => _}, behaviors(entity))
  end

  @doc "Returns a property for this entity, including looking up the prototype chain"
  def(get_prop(nil, _), do: :error)

  def get_prop(%Entity{proto: prototype_id, props: props}, key) do
    Map.get_lazy(props, key, fn -> get_prop(World.get_entity(prototype_id), key) end)
  end

  @doc "Returns {<new value>, entity}"
  def set_prop(entity = %Entity{props: props}, key, value) do
    {value, %{entity | props: Map.put(props, key, value)}}
  end

  @doc """
  Returns whether the passed 'name' can be used to refer to this entity

    'red pen' -> <redpen>
    'red' -> <redpen>
    'pen' -> <redpen>, <bluepen>
  """
  def named?(_, nil), do: false

  def named?(entity, name) do
    entity.name_tokens
    |> MapSet.member?(String.downcase(name))
  end

  def name(entity) do
    entity.name || entity.id
  end

  def is_person?(entity) do
    entity
    |> has_behavior?(Doro.Behaviors.Player)
  end

  defp generate_id() do
    Base.encode32(:crypto.strong_rand_bytes(8), padding: false, case: :lower)
  end

  defp generate_id(prefix) do
    "#{prefix}-#{generate_id()}"
  end

  def preprocess_name(entity_params = %{id: id}) do
    entity_params = Map.put(entity_params, :name, Map.get(entity_params, :name, id))
    downcased = String.downcase(entity_params.name)
    Map.put(entity_params, :name_tokens, MapSet.new([downcased | String.split(downcased)]))
  end

  @behaviour Access

  @impl Access
  def fetch(entity, key) do
    case get_prop(entity, key) do
      :error -> :error
      value -> {:ok, value}
    end
  end

  @impl Access
  def get(entity, key, default \\ nil) do
    case get_prop(entity, key) do
      :error -> default
      value -> value
    end
  end

  # This behavior is wrong I think
  @impl Access
  def pop(entity, key, default \\ nil) do
    {value, new_props} = Map.pop(entity, key, default)
    {value, %{entity | props: new_props}}
  end

  # This behavior is wrong I think
  @impl Access
  def get_and_update(entity, key, fun) do
    {value, new_props} = Map.get_and_update(entity.props, key, fun)
    {value, %{entity | props: new_props}}
  end
end
