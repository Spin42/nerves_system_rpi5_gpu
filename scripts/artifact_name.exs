# Prints the file name of this system's Nerves artifact,
# <app>-portable-<version>-<checksum>.tar.gz, without building anything.
#
#     elixir scripts/artifact_name.exs
#
# `mix nerves.artifact.details` gives the same name but runs
# `nerves.precompile` first, which builds the system if it isn't built yet.
# This mirrors Nerves.Artifact.download_name/1 and checksum/1 (nerves 1.12):
# a SHA-256 over the SHA-256 of every file in the package's :checksum list.

Mix.start()

system_dir = Path.expand("..", __DIR__)

Mix.Project.in_project(:artifact_name, system_dir, fn _module ->
  config = Mix.Project.config()
  package = config[:nerves_package]
  :system = package[:type]

  files =
    package[:checksum]
    |> Enum.map(&Path.join(system_dir, &1))
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.flat_map(fn path ->
      if File.dir?(path), do: Path.wildcard(Path.join(path, "**")), else: [path]
    end)
    |> Enum.map(&Path.expand/1)
    |> Enum.filter(&File.regular?/1)
    |> Enum.uniq()

  checksum =
    files
    |> Enum.map(&:crypto.hash(:sha256, File.read!(&1)))
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16()
    |> binary_part(0, 7)

  IO.puts("#{config[:app]}-portable-#{config[:version]}-#{checksum}.tar.gz")
end)
