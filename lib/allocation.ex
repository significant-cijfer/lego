defmodule Lego.Allocation do
  use TypedStruct

  alias Lego.Allocation.Interval
  alias Lego.Graph
  alias Lego.Inst
  alias Lego.Location
  alias Lego.Space

  typedstruct enforce: true do
    field :intervals, intervals(), default: %{}
    field :spaces, spaces(), default: %{}
  end

  typedstruct module: Interval, enforce: true do
    field :start, non_neg_integer()
    field :end, non_neg_integer() | nil
  end

  @type algorithm() :: :linear
  @type intervals() :: %{ Location.t() => Interval.t() }
  @type spaces() :: %{ Location.t() => Space.t() }

  @spec scan(algorithm(), Graph.t()) :: t()
  def scan(:linear, graph) do
    build_intervals(graph)

    %__MODULE__{}
  end

  @spec build_intervals(Graph.t()) :: intervals()
  def build_intervals(graph) do
    dbg graph.blocks
      |> Enum.map(fn block -> block.insts end)
      |> List.flatten()
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.reduce(%{}, &update_interval/2)
  end

  @spec update_interval({Inst.t(), integer()}, intervals()) :: intervals()
  def update_interval({inst, index}, map) do
    map
      |> update_reads(inst, index)
      |> update_writes(inst, index)
  end

  @spec update_reads(intervals(), Inst.t(), integer()) :: intervals()
  def update_reads(map, inst, index) do
    inst
      |> Inst.reads()
      |> Enum.reduce(map, fn read, map ->
        Map.update!(map, read, fn iv -> %{ iv | end: index } end)
      end)
  end

  @spec update_writes(intervals(), Inst.t(), integer()) :: intervals()
  def update_writes(map, inst, index) do
    inst
      |> Inst.writes()
      |> Enum.reduce(map, fn write, map ->
        Map.put_new(map, write, %Interval{ start: index, end: nil })
      end)
  end
end
