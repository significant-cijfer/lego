defmodule Lego do
  @moduledoc """
  Documentation for `Lego`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Lego.hello()
      :world

  """
  def hello do
    graph = %Lego.Graph{}

    Lego.Graph.emit(graph)

    graph
  end
end
