defmodule Lego.Flow do
  use TypedStruct

  typedstruct module: Continue, enforce: true do
    field :block, non_neg_integer()
  end

  typedstruct module: Conditional, enforce: true do
    field :condition, non_neg_integer()
    field :success, non_neg_integer()
    field :failure, non_neg_integer()
  end

  typedstruct module: Stop, enforce: true do
    field :value, non_neg_integer()
  end

  @type t() ::
    Continue
    | Conditional
    | Stop
end
