defmodule Lego.Block do
  use TypedStruct

  alias Lego.Inst
  alias Lego.Flow

  typedstruct do
    field :insts, [Inst.t()], default: []
    field :flow, Lego.Flow.t()
  end

  @spec add_inst(t(), Inst.t()) :: t()
  def add_inst(block, inst) do
    %{ block | insts: [inst | block.insts] }
  end

  @spec set_flow(t(), Flow.t()) :: t()
  def set_flow(block, flow) do
    %{ block | flow: flow }
  end
end
