defmodule Mix.Tasks.Nvidia.Bundles.Upload do
  @shortdoc "Upload the NVIDIA CUDA/cuDNN/NCCL/NVSHMEM bundles to a device"

  @moduledoc """
  Uploads the CUDA toolkit, cuDNN, NCCL and NVSHMEM bundles expected by this system to
  a device's data partition (`/root/nvidia/`), verifies them and mounts them.

      mix nvidia.bundles.upload [host] [--dir DIR] [--keep-old]

  `host` defaults to `nerves.local`. Bundles are read from `--dir`, by default
  `$NERVES_DL_DIR/nvidia-bundles` (`~/.nerves/dl/nvidia-bundles`), where
  `scripts/build-nvidia-bundles.sh` writes them.

  Bundles already on the device with a matching checksum are skipped. Each
  upload goes to a `.partial` file, is checked with SHA-256 on the device and
  then renamed. Other versions of the bundles are deleted unless they are in
  use or `--keep-old` is given. The new bundles are mounted right away
  (`nvidia-init --mount-bundles`); a component that is still mounted from an
  older bundle switches over at the next reboot.

  Uses the `ssh` and `sftp` commands, so your SSH config and agent apply.
  """
  use Mix.Task

  @remote_dir "/root/nvidia"
  @system_dir Path.expand("../../..", __DIR__)

  @impl Mix.Task
  def run(args) do
    {opts, argv} = OptionParser.parse!(args, strict: [dir: :string, keep_old: :boolean])
    host = List.first(argv) || "nerves.local"
    dir = opts[:dir] || Path.join(dl_dir(), "nvidia-bundles")
    bundles = expected_bundles(dir)

    remote = remote(host, status_code(bundles))

    for bundle <- bundles do
      if remote[bundle.file] == bundle.sha256 do
        Mix.shell().info("#{bundle.file}: already on #{host}")
      else
        upload(host, bundle)
      end
    end

    unless opts[:keep_old] do
      for file <- remote(host, cleanup_code(bundles)) do
        Mix.shell().info("Removed old bundle #{file}")
      end
    end

    for {component, mounted_from} <- remote(host, mount_code()) do
      expected = Enum.find(bundles, &(&1.component == component))

      cond do
        mounted_from == nil ->
          Mix.shell().error("#{component}: not mounted, check `dmesg` on the device")

        String.ends_with?(mounted_from, " (deleted)") ->
          Mix.shell().info(
            "#{component}: #{expected.file} was replaced while mounted, reboot to use the new one"
          )

        Path.basename(mounted_from) == expected.file ->
          Mix.shell().info("#{component}: mounted on /opt/nvidia/#{component}")

        true ->
          Mix.shell().info(
            "#{component}: still using #{Path.basename(mounted_from)}, reboot to switch to #{expected.file}"
          )
      end
    end
  end

  defp upload(host, bundle) do
    size = File.stat!(bundle.path).size
    Mix.shell().info("Uploading #{bundle.file} (#{div(size, 1_000_000)} MB) to #{host}...")

    batch =
      Path.join(System.tmp_dir!(), "nvidia-bundles-#{System.unique_integer([:positive])}.sftp")

    File.write!(batch, """
    -mkdir #{@remote_dir}
    put #{bundle.path} #{@remote_dir}/#{bundle.file}.partial
    """)

    try do
      case System.cmd("sftp", ["-q", "-b", batch, host], stderr_to_stdout: true) do
        {_, 0} -> :ok
        {out, _} -> Mix.raise("sftp upload of #{bundle.file} failed:\n#{out}")
      end
    after
      File.rm(batch)
    end

    Mix.shell().info("Verifying #{bundle.file} on #{host}...")

    case remote(host, finalize_code(bundle)) do
      :ok -> Mix.shell().info("#{bundle.file}: installed")
      {:error, reason} -> Mix.raise("#{bundle.file}: #{reason}")
    end
  end

  # Device-side snippets. They run in the device's IEx over ssh and print
  # their result as an encoded term (see remote/2).

  defp status_code(bundles) do
    files = Enum.map(bundles, & &1.file)

    """
    for f <- #{inspect(files)}, into: %{} do
      marker = Path.join(#{inspect(@remote_dir)}, f <> ".sha256")
      sha = if File.exists?(Path.join(#{inspect(@remote_dir)}, f)), do: File.read(marker) |> elem(1), else: nil
      {f, if(is_binary(sha), do: String.trim(sha))}
    end
    """
  end

  defp finalize_code(bundle) do
    """
    partial = Path.join(#{inspect(@remote_dir)}, #{inspect(bundle.file <> ".partial")})
    sha =
      partial
      |> File.stream!(4_194_304)
      |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
      |> :crypto.hash_final()
      |> Base.encode16(case: :lower)

    if sha == #{inspect(bundle.sha256)} do
      final = Path.join(#{inspect(@remote_dir)}, #{inspect(bundle.file)})
      File.rename!(partial, final)
      File.write!(final <> ".sha256", sha <> "\\n")
      :ok
    else
      File.rm(partial)
      {:error, "checksum mismatch after upload (got " <> sha <> ")"}
    end
    """
  end

  defp cleanup_code(bundles) do
    keep = Enum.flat_map(bundles, &[&1.file, &1.file <> ".sha256"])

    """
    in_use =
      for f <- Path.wildcard("/sys/block/loop*/loop/backing_file"),
          {:ok, path} = File.read(f),
          do: String.trim(path)

    for path <- Path.wildcard(#{inspect(@remote_dir)} <> "/nvidia-*-aarch64.squashfs*"),
        Path.basename(path) not in #{inspect(keep)},
        String.replace_suffix(path, ".sha256", "") not in in_use,
        File.rm(path) == :ok,
        do: Path.basename(path)
    """
  end

  defp mount_code do
    """
    System.cmd("/usr/sbin/nvidia-init", ["--mount-bundles"])

    backing =
      for f <- Path.wildcard("/sys/block/loop*/loop/backing_file"), into: %{} do
        {"/dev/" <> (f |> Path.split() |> Enum.at(3)), f |> File.read!() |> String.trim()}
      end

    mounts =
      for line <- File.read!("/proc/mounts") |> String.split("\\n"),
          [dev, "/opt/nvidia/" <> component | _] <- [String.split(line)],
          into: %{},
          do: {component, backing[dev]}

    for line <- File.read!("/etc/nvidia-bundles") |> String.split("\\n", trim: true) do
      [component | _] = String.split(line)
      {component, mounts[component]}
    end
    """
  end

  defp remote(host, code) do
    wrapped =
      "IO.puts(\"@@RESULT:\" <> Base.encode64(:erlang.term_to_binary((fn -> #{code} end).())))"

    case System.cmd("ssh", [host, wrapped], stderr_to_stdout: true) do
      {out, 0} ->
        case Regex.run(~r/@@RESULT:([A-Za-z0-9+\/=]+)/, out) do
          [_, encoded] -> encoded |> Base.decode64!() |> :erlang.binary_to_term()
          nil -> Mix.raise("Unexpected reply from #{host}:\n#{out}")
        end

      {out, _} ->
        Mix.raise("ssh #{host} failed:\n#{out}")
    end
  end

  defp expected_bundles(dir) do
    versions =
      for line <- File.read!(Path.join(@system_dir, "nvidia-versions")) |> String.split("\n"),
          [key, value] <- [String.split(line, "=", parts: 2)],
          not String.starts_with?(key, "#"),
          into: %{},
          do: {String.trim(key), String.trim(value)}

    [
      {"cuda", "nvidia-cuda-" <> versions["NVIDIA_STACK_CUDA_VERSION"]},
      {"cudnn", "nvidia-cudnn-" <> versions["NVIDIA_STACK_CUDNN_VERSION"]},
      {"nccl", "nvidia-nccl-" <> versions["NVIDIA_STACK_NCCL_VERSION"]},
      {"nvshmem", "nvidia-nvshmem-" <> versions["NVIDIA_STACK_NVSHMEM_VERSION"]}
    ]
    |> Enum.map(fn {component, id} ->
      file = id <> "-aarch64.squashfs"
      path = Path.join(dir, file)

      unless File.exists?(path) and File.exists?(path <> ".sha256") do
        Mix.raise("""
        #{path} not found. Build the bundles first:

            #{Path.join(@system_dir, "scripts/build-nvidia-bundles.sh")}
        """)
      end

      [sha256 | _] = File.read!(path <> ".sha256") |> String.split()
      %{component: component, file: file, path: path, sha256: sha256}
    end)
  end

  defp dl_dir do
    System.get_env("NERVES_DL_DIR") || Path.join(System.user_home!(), ".nerves/dl")
  end
end
