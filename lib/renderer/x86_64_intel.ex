defmodule Lego.Renderer.X8664Intel do
  use TypedStruct

  alias Lego.Renderer
  alias Lego.Flow
  alias Lego.Inst

  import Structo

  typedstruct do
    field :dummy, default: nil
  end

  defimpl Renderer, for: __MODULE__ do
    def render(_renderer, device, graph) do
      Enum.each(graph.blocks, fn block ->
        block.insts
          |> Enum.reverse()
          |> Enum.each(fn inst ->
            IO.write(device, case inst do
              ~m{:Inst.Put, dst, src} -> "\tmov #{dst}, #{src}\n"
              ~m{:Inst.Add, dst, lhs, rhs} -> "\tmov #{dst}, #{lhs}\n" <> "\tadd #{dst}, #{rhs}\n"
            end)
          end)

        #case block.flow
        IO.write(device, case block.flow do
          ~m{:Flow.Stop, value} -> "\tmov rax, #{value}\n" <> "\tret\n"
        end)
        #IO.inspect(device, block.flow, [])
      end)
    end
  end
end
