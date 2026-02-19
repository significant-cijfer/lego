defmodule Lego.Inst do
  use TypedStruct

  alias Lego.Location

  typedstruct module: Add, enforce: true do
    field :dst, Location.t()
    field :lhs, Location.t()
    field :rhs, Location.t()
  end

  @type t() ::
    Add.t()
end
