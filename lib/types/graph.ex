defmodule Lego.Graph do
  defstruct blocks: []

  def add_block(graph, block) do
    %{ graph | blocks: [block | graph.blocks] }
  end

  def emit(device \\ :stdio, _graph) do
    IO.write(device, "graph: ???\n")
  end
end
