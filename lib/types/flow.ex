defmodule Lego.Flow do
  use TypedStruct

  alias Lego.Inst
  alias Lego.Location

  import Structo

  typedstruct module: Continue, enforce: true do
    field :block, non_neg_integer()
  end

  typedstruct module: Conditional, enforce: true do
    field :condition, Location.t()
    field :success, non_neg_integer()
    field :failure, non_neg_integer()
  end

  typedstruct module: Stop, enforce: true do
    field :value, Location.t()
  end

  @type t() ::
    Continue.t()
    | Conditional.t()
    | Stop.t()

  @spec to_inst(t()) :: Inst.Nop.t()
  def to_inst(flow) do
    case flow do
      ~m{:Continue} -> %Inst.Nop{src: nil}
      ~m{:Conditional, condition} -> %Inst.Nop{src: condition}
      ~m{:Stop, value} -> %Inst.Nop{src: value}
    end
  end
end
