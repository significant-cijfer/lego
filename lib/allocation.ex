defmodule Lego.Allocation do
  use TypedStruct

  alias Lego.Allocation.Interval
  alias Lego.Graph
  alias Lego.Flow
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
    registers = MapSet.new([
      {:register, "ra"},
      {:register, "rb"},
      {:register, "rc"},
      {:register, "rd"},
    ])

    {_, active} =
      build_intervals(graph)
      |> Enum.filter(fn {_, a} -> a.end != nil end)
      |> Enum.sort(fn {_, a}, {_, b} -> a.start <= b.start end)
      |> Enum.reduce({registers, %{}}, &handle_interval/2)

    spaces =
      active
      |> Map.new(fn {loc, {_, space}} -> {loc, space} end)

    %__MODULE__{spaces: spaces}
  end

  @spec build_intervals(Graph.t()) :: intervals()
  def build_intervals(graph) do
    #dbg graph.blocks
    graph.blocks
      |> Enum.flat_map(fn block -> Enum.reverse(block.insts) ++ [Flow.to_inst(block.flow)] end)
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

  @spec handle_interval(interval(), {pool(), active()}) :: {pool(), active()}
  def handle_interval({k, v}, ctx) do
    ctx = expire_old_intervals(v, ctx)
    ctx = insert_interval({k, v}, ctx)
    ctx
  end

  @spec expire_old_intervals(Interval.t(), {pool(), active()}) :: {pool(), active()}
  def expire_old_intervals(current, {pool, active}) do
    #dbg active
    active
      |> Enum.sort(fn {_, {a, _}}, {_, {b, _}} -> a.end <= b.end end)
      |> Enum.filter(fn {_, {a, _}} -> a.end <= current.start end)
      |> Enum.reduce({pool, active}, &expire_interval/2)
  end

  @spec expire_interval({Location.t(), {Interval.t(), Space.t()}}, {pool(), active()}) :: {pool(), active()}
  def expire_interval({_k, {_iv, :stack}}, {pool, active}) do
    {
      pool,
      active
    }
  end

  def expire_interval({_k, {_iv, register}}, {pool, active}) do
    {
      MapSet.put(pool, register),
      active
    }
  end

  @spec insert_interval(interval(), {pool(), active()}) :: {pool(), active()}
  def insert_interval({k, v}, {pool, active}) do
    if Enum.empty?(pool) do
      spill_at_interval({k, v}, {pool, active})
    else
      register = Enum.at(pool, 0)
      {
        MapSet.delete(pool, register),
        Map.put(active, k, {v, register})
      }
    end
  end

  @spec spill_at_interval(interval(), {pool(), active()}) :: {pool(), active()}
  def spill_at_interval({k, v}, {pool, active}) do
    {spill, {s_v, s_s}} =
      active
      |> Enum.filter(fn {_, {_, space}} -> space != :stack end)
      |> Enum.max_by(fn {_, {a, _}} -> a.end end)

    if s_v.end > v.end do
      {
        pool,
        active
          |> Map.put(spill, {s_v, :stack})
          |> Map.put(k, {v, s_s})
      }
    else
      {
        pool,
        active
          |> Map.put(k, {v, :stack})
      }
    end
  end
end
