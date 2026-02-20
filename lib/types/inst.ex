defmodule Lego.Inst do
  use TypedStruct

  alias Lego.Location
  alias Lego.Constant

  import Structo

  typedstruct module: Put, enforce: true do
    field :dst, Location.t()
    field :src, Constant.t()
  end

  typedstruct module: Add, enforce: true do
    field :dst, Location.t()
    field :lhs, Location.t()
    field :rhs, Location.t()
  end

  @type t() ::
    Put.t()
    | Add.t()

  @spec reads(t()) :: [Location.t()]
  def reads(inst) do
    case inst do
      ~m{:Put} -> []
      ~m{:Add, lhs, rhs} -> [lhs, rhs]
    end
  end

  @spec writes(t()) :: [Location.t()]
  def writes(inst) do
    case inst do
      ~m{:Put, dst} -> [dst]
      ~m{:Add, dst} -> [dst]
    end
  end
end
