defmodule Lego.Graph do
  use TypedStruct

  typedstruct do
    field :blocks, [Lego.Block.t()], default: []
  end

  def add_block(graph, block) do
    %{ graph | blocks: [block | graph.blocks] }
  end
end
