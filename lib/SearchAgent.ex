defmodule SearchAgent do
  use GenServer

  def start_link({server_pid, system_name, filepath, target_numbers}) do
    GenServer.start_link(__MODULE__, {server_pid, system_name, filepath, target_numbers})
  end

  def init({server_pid, system_name, filepath, target_numbers}) do
    Task.start(fn -> search_numbers(server_pid, system_name, filepath, target_numbers) end)
    {:ok, %{server: server_pid, system: system_name}}
  end

  defp search_numbers(server_pid, system_name, filepath, target_numbers) do
    start_time = :os.system_time(:millisecond)

    case RemoteFileReader.read_file(:"#{system_name}", filepath) do
      {:ok, content} ->
        results =
          content
          |> String.split("\n", trim: true)
          |> Enum.with_index(1)
          |> Enum.filter(fn {line, _} ->
            clean_number = String.trim(line) |> String.to_integer()
            clean_number in target_numbers
          end)

        end_time = :os.system_time(:millisecond)
        elapsed_time = end_time - start_time

        send(server_pid, {:search_complete, system_name, results, elapsed_time})

      {:error, reason} ->
        IO.puts("Error reading file: #{reason}")
        send(server_pid, {:search_complete, system_name, [], 0})
    end
  end
end
