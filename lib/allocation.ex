defmodule Lego.Allocation do
  use TypedStruct

  alias Lego.Allocation.Interval
  alias Lego.Graph
  alias Lego.Inst
  alias Lego.Location
  alias Lego.Space

  typedstruct enforce: true do
    field :spaces, spaces(), default: %{}
  end

  typedstruct module: Interval, enforce: true do
    field :start, non_neg_integer()
    field :end, non_neg_integer() | nil
  end

  @type algorithm() :: :linear
  @type intervals() :: %{ Location.t() => Interval.t() }
  @type spaces() :: %{ Location.t() => Space.t() }

  @type interval() :: { Location.t(), Interval.t() }
  @type space() :: { Location.t(), Space.t() }

  @type active() :: %{ Location.t() => {Interval.t(), Space.t()} }
  @type pool() :: MapSet.t(Space.t())

  @spec scan(algorithm(), Graph.t()) :: t()
  def scan(:linear, graph) do
    intervals = build_intervals(graph)
    registers = MapSet.new([
      {:register, "ra"},
      {:register, "rb"},
      {:register, "rc"},
      {:register, "rd"},
    ])

    #dbg intervals
    intervals
      |> Enum.sort(fn {_, a}, {_, b} -> a.start <= b.start end)
      |> Enum.reduce({registers, %{}}, &handle_interval/2)

    %__MODULE__{}
  end

  @spec build_intervals(Graph.t()) :: intervals()
  def build_intervals(graph) do
    #dbg graph.blocks
    graph.blocks
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

  @spec handle_interval(interval(), {pool(), active()}) :: {pool(), active()} | :todo
  def handle_interval({k, v}, ctx) do
    ctx = expire_old_intervals(v, ctx)
    ctx = insert_interval({k, v}, ctx)
    ctx
  end

  @spec expire_old_intervals(Interval.t(), {pool(), active()}) :: {pool(), active()}
  def expire_old_intervals(current, {pool, active}) do
    dbg active
      |> Enum.sort(fn {_, {a, _}}, {_, {b, _}} -> a.end <= b.end end)
      |> Enum.filter(fn {_, {a, _}} -> a.end <= current.start end)
      |> Enum.reduce({pool, active}, &expire_interval/2)
  end

  @spec expire_interval({Location.t(), {Interval.t(), Space.t()}}, {pool(), active()}) :: {pool(), active()}
  def expire_interval({k, {_iv, space}}, {pool, active}) do
    {
      MapSet.put(pool, space),
      Map.delete(active, k)
    }
  end

  @spec insert_interval(interval(), {pool(), active()}) :: {pool(), active()} | :todo
  def insert_interval({k, v}, {pool, active}) do
    if Enum.empty?(pool) do
        :todo
    else
      register = Enum.at(pool, 0)
      {
          MapSet.delete(pool, register),
          Map.put(active, k, {v, register})
      }
    end
  end
end
