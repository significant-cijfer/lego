defmodule Lego.Block do
  use TypedStruct

  typedstruct enforce: true do
    field :instructions, [Lego.Instruction.t()]
    field :flow, Lego.Flow.t()
  end

  def add_inst(block, inst) do
    %{ block | insts: [inst | block.insts] }
  end

  def set_flow(block, flow) do
    %{ block | flow: flow }
  end
end
