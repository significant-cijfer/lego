defmodule Lego.Flow do
  use TypedStruct

  alias Lego.Location

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
end
