defmodule SearchAgent do
  @moduledoc """
  Agent responsible for searching numbers in remote files.
  Each agent connects to a remote system and searches for target numbers.
  """
  use GenServer
  require Logger

  @type search_result :: {String.t(), non_neg_integer()}

  @spec start_link({pid(), atom(), String.t(), [integer()]}) :: GenServer.on_start()
  def start_link({server_pid, system_name, filepath, target_numbers}) do
    GenServer.start_link(__MODULE__, {server_pid, system_name, filepath, target_numbers})
  end

  @impl GenServer
  def init({server_pid, system_name, filepath, target_numbers}) do
    Logger.info("Starting search on #{system_name} for #{length(target_numbers)} target numbers")
    Task.start(fn -> search_numbers(server_pid, system_name, filepath, target_numbers) end)
    {:ok, %{server: server_pid, system: system_name}}
  end

  @spec search_numbers(pid(), atom(), String.t(), [integer()]) :: :ok
  defp search_numbers(server_pid, system_name, filepath, target_numbers) do
    start_time = :os.system_time(:millisecond)
    target_set = MapSet.new(target_numbers)

    result =
      case RemoteFileReader.read_file(:"#{system_name}", filepath) do
        {:ok, content} ->
          process_content(content, target_set)

        {:error, reason} ->
          Logger.error("Error reading file on #{system_name}: #{reason}")
          []
      end

    end_time = :os.system_time(:millisecond)
    elapsed_time = end_time - start_time

    send(server_pid, {:search_complete, system_name, result, elapsed_time})
  end

  @spec process_content(String.t(), MapSet.t()) :: [search_result()]
  defp process_content(content, target_set) do
    content
    |> String.split("\n", trim: true)
    |> Stream.with_index(1)
    |> Stream.map(fn {line, index} ->
      {String.trim(line), index}
    end)
    |> Stream.filter(fn {line, _index} ->
      case Integer.parse(line) do
        {number, ""} -> MapSet.member?(target_set, number)
        _ -> false
      end
    end)
    |> Enum.to_list()
  end
end
