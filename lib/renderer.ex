defprotocol Lego.Renderer do
  alias Lego.Graph

  @spec render(t(), IO.device(), Graph.t()) :: :ok
  def render(renderer, device \\ :stdio, graph)
end
