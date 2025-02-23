defmodule RemoteFileReader do
  def read_file(remote_node, file_path) do
    if Node.connect(remote_node) do
      case :rpc.call(remote_node, File, :read, [file_path]) do
        {:ok, content} ->
          {:ok, content}

        {:error, reason} ->
          {:error, "Failed to read file: #{reason}"}
      end
    else
      IO.puts("Failed to connect to #{remote_node}. Please ensure the remote node is running.")
      {:error, "Failed to connect to remote node"}
    end
  end
end
