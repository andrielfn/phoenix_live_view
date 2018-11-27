defmodule Phoenix.LiveView.Diff do
  @moduledoc false
  alias Phoenix.LiveView.Rendered

  # entry point
  # {thing_to_be_serialized, fingerprint_tree} = traverse(result, nil)

  # nexttime
  # {thing_to_be_serialized, fingerprint_tree} = traverse(result, fingerprint_tree)

  # todo comprehensions (no need for recursive)

  def render(%Rendered{} = rendered, fingerprint_tree \\ nil) do
    traverse(rendered, fingerprint_tree)
  end

  defp traverse(%Rendered{fingerprint: fingerprint, dynamic: dynamic}, {fingerprint, children}) do
    {_counter, diff, children} = traverse_dynamic(dynamic, children)
    {%{dynamic: diff}, {fingerprint, children}}
  end

  defp traverse(%Rendered{fingerprint: fingerprint, static: static, dynamic: dynamic}, _) do
    {_counter, diff, children} = traverse_dynamic(dynamic, %{})
    {%{static: static, dynamic: diff}, {fingerprint, children}}
  end

  defp traverse(nil, _) do
    {nil, nil}
  end

  defp traverse(iodata, _) do
    {IO.iodata_to_binary(iodata), nil}
  end

  defp traverse_dynamic(dynamic, children)  do
    Enum.reduce(dynamic, {0, %{}, children}, fn entry, {counter, diff, children} ->
      {serialized, child_fingerprint} = traverse(entry, Map.get(children, counter))

      diff =
        if serialized do
          Map.put(diff, counter, serialized)
        else
          diff
        end

      children =
        if child_fingerprint do
          Map.put(children, counter, child_fingerprint)
        else
          Map.delete(children, counter)
        end

      {counter + 1, diff, children}
    end)
  end
end
