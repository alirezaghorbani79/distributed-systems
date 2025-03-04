defmodule MainAgent do
  @moduledoc """
  Coordinates a distributed search operation across multiple systems.

  The MainAgent dispatches SearchAgent processes to find target numbers in a file
  across multiple systems, collects their results, and manages the overall search
  operation until completion.
  """
  use GenServer

  @spec start_link([integer()], [atom() | String.t()]) :: GenServer.on_start()
  def start_link(target_numbers, systems) do
    GenServer.start_link(__MODULE__, {target_numbers, systems}, name: __MODULE__)
  end

  @spec init({[integer()], [atom() | String.t()]}) ::
          {:ok, map(), {:continue, :start_agents}}
  def init({target_numbers, systems}) do
    state = %{
      target_numbers: target_numbers,
      remaining_systems: systems,
      in_progress: %{},
      results: []
    }

    {:ok, state, {:continue, :start_agents}}
  end

  @spec handle_continue(:start_agents, map()) :: {:noreply, map()}
  def handle_continue(:start_agents, state) do
    {systems, remaining} = Enum.split(state.remaining_systems, 2)
    new_state = Enum.reduce(systems, state, &start_search_agent(&1, &2))
    {:noreply, %{new_state | remaining_systems: remaining}}
  end

  @spec handle_info(
          {:search_complete, atom() | String.t(), [{integer(), integer()}], integer()},
          map()
        ) ::
          {:stop, :normal, map()} | {:noreply, map()}
  def handle_info({:search_complete, system, results, elapsed_time}, state) do
    new_results = state.results ++ results

    new_state = %{
      state
      | results: new_results,
        in_progress: Map.delete(state.in_progress, system)
    }

    IO.puts("Search complete on #{system} in #{elapsed_time} ms")

    Enum.each(results, fn {num, line} ->
      IO.puts("Found #{num} on #{system} at line #{line}")
    end)

    if state.remaining_systems == [] and map_size(new_state.in_progress) == 0 do
      IO.puts("All searches complete. Found results: #{inspect(new_results)}")
      {:stop, :normal, new_state}
    else
      {new_state, remaining} = schedule_next_agent(new_state)
      {:noreply, %{new_state | remaining_systems: remaining}}
    end
  end

  @spec start_search_agent(atom() | String.t(), map()) :: map()
  defp start_search_agent(system, state) do
    filepath = "D:/aos/findme.txt"
    {:ok, pid} = SearchAgent.start_link({self(), system, filepath, state.target_numbers})
    %{state | in_progress: Map.put(state.in_progress, system, pid)}
  end

  @spec schedule_next_agent(map()) :: {map(), [atom() | String.t()]}
  defp schedule_next_agent(state) do
    case state.remaining_systems do
      [next | rest] ->
        {start_search_agent(next, state), rest}

      [] ->
        {state, []}
    end
  end
end
