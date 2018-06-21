defmodule Doro.Context do
  alias Doro.GameState

  defstruct original_command: nil,
            subject: nil,
            object: nil,
            verb: nil,
            handled: false

  @doc "Creates a Context given some incoming request params"
  @spec create(String.t(), String.t(), String.t(), String.t() | nil) :: {:ok, %Doro.Context{}}
  def create(original_command, player_id, verb, object_id) do
    {
      :ok,
      %Doro.Context{
        original_command: original_command,
        subject: GameState.get_entity(player_id),
        object: GameState.get_entity(object_id) || GameState.get_entity(player_id),
        verb: verb
      }
    }
  end

  def location(ctx) do
    Doro.GameState.get_entity(ctx.subject.props.location)
  end
end
