defmodule RemoteFileReader do
  @moduledoc """
  Module for reading files from remote nodes.
  Provides functionality to connect to remote nodes and read file contents.
  """
  require Logger

  @doc """
  Reads a file from a remote node.
  Returns {:ok, content} if successful, or {:error, reason} if the read fails.
  """
  @spec read_file(atom(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def read_file(remote_node, file_path) do
    if Node.connect(remote_node) do
      case :rpc.call(remote_node, File, :read, [file_path], 30000) do
        {:ok, content} ->
          {:ok, content}

        {:error, reason} ->
          {:error, "Failed to read file: #{reason}"}

        {:badrpc, reason} ->
          {:error, "RPC call failed: #{inspect(reason)}"}
      end
    else
      Logger.error("Failed to connect to #{remote_node}")
      {:error, "Failed to connect to remote node"}
    end
  end
end
