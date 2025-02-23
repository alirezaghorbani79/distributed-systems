# defmodule RemoteFileReader do
#   def read_file(remote_node, file_path) do
#     if Node.connect(remote_node) do
#       case :rpc.call(remote_node, File, :read, [file_path]) do
#         {:ok, content} ->
#           {:ok, content}

#         {:error, reason} ->
#           {:error, "Failed to read file: #{reason}"}
#       end
#     else
#       IO.puts("Failed to connect to #{remote_node}. Please ensure the remote node is running.")
#       {:error, "Failed to connect to remote node"}
#     end
#   end
# end

# defmodule SearchAgent do
#   use GenServer

#   def start_link({server_pid, system_name, filepath, target_numbers}) do
#     GenServer.start_link(__MODULE__, {server_pid, system_name, filepath, target_numbers})
#   end

#   def init({server_pid, system_name, filepath, target_numbers}) do
#     Task.start(fn -> search_numbers(server_pid, system_name, filepath, target_numbers) end)
#     {:ok, %{server: server_pid, system: system_name}}
#   end

#   defp search_numbers(server_pid, system_name, filepath, target_numbers) do
#     start_time = :os.system_time(:millisecond)

#     case File.read(filepath) do
#       {:ok, content} ->
#         results =
#           content
#           |> String.split("\n", trim: true)
#           |> Enum.with_index(1)
#           |> Enum.filter(fn {line, _} ->
#             clean_number = String.trim(line) |> String.to_integer()
#             clean_number in target_numbers
#           end)

#         end_time = :os.system_time(:millisecond)
#         elapsed_time = end_time - start_time

#         send(server_pid, {:search_complete, system_name, results, elapsed_time})

#       {:error, _} ->
#         send(server_pid, {:search_complete, system_name, [], 0})
#     end
#   end
# end

# defmodule MainAgent do
#   use GenServer

#   def start_link(target_numbers, systems, base_path) do
#     GenServer.start_link(__MODULE__, {target_numbers, systems, base_path}, name: __MODULE__)
#   end

#   def init({target_numbers, systems, _base_path}) do
#     state = %{
#       target_numbers: target_numbers,
#       remaining_systems: systems,
#       in_progress: %{},
#       results: []
#     }

#     {:ok, state, {:continue, :start_agents}}
#   end

#   def handle_continue(:start_agents, state) do
#     {systems, remaining} = Enum.split(state.remaining_systems, 2)
#     new_state = Enum.reduce(systems, state, &start_search_agent(&1, &2))
#     {:noreply, %{new_state | remaining_systems: remaining}}
#   end

#   def handle_info({:search_complete, system, results, elapsed_time}, state) do
#     new_results = state.results ++ results

#     new_state = %{
#       state
#       | results: new_results,
#         in_progress: Map.delete(state.in_progress, system)
#     }

#     IO.puts("Search complete on #{system} in #{elapsed_time} ms")

#     Enum.each(results, fn {num, line} ->
#       IO.puts("Found #{num} on #{system} at line #{line}")
#     end)

#     if state.remaining_systems == [] and map_size(new_state.in_progress) == 0 do
#       IO.puts("All searches complete. Found results: #{inspect(new_results)}")
#       {:stop, :normal, new_state}
#     else
#       {new_state, remaining} = schedule_next_agent(new_state)
#       {:noreply, %{new_state | remaining_systems: remaining}}
#     end
#   end

#   defp start_search_agent(system, state) do
#     filepath = "D:/aos/findme.txt"
#     {:ok, pid} = SearchAgent.start_link({self(), system, filepath, state.target_numbers})
#     %{state | in_progress: Map.put(state.in_progress, system, pid)}
#   end

#   defp schedule_next_agent(state) do
#     case state.remaining_systems do
#       [next | rest] ->
#         {start_search_agent(next, state), rest}

#       [] ->
#         {state, []}
#     end
#   end
# end

# defmodule RemoteFileReader do
#   def read_file(file_path) do
#     case File.read(file_path) do
#       {:ok, content} -> content
#       {:error, reason} -> "Failed to read file: #{reason}"
#     end
#   end
# end
