defmodule Lego do
  @moduledoc """
  Documentation for `Lego`.
  """

  alias Lego.Allocation
  alias Lego.Renderer
  alias Lego.Graph
  alias Lego.Block
  alias Lego.Flow
  alias Lego.Inst

  import Graph
  import Block

  def hello do
    :world
  end

  def example() do
    block0 = %Block{}
      |> add_inst(%Inst.Put{ dst: "a", src: 10 })
      |> add_inst(%Inst.Put{ dst: "b", src: 10 })
      |> add_inst(%Inst.Add{ dst: "c", lhs: "a", rhs: "b" })
      |> set_flow(%Flow.Stop{ value: "c" })

    graph = %Graph{}
      |> add_block(block0)

    Allocation.scan(:linear, graph)

    Renderer.render(%Renderer.X8664Intel{}, graph)
  end
end
