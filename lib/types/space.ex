defmodule Lego.Space do
  @type t() ::
    :stack
    | {:register, String.t()}
end
