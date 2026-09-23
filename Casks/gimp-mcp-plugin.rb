# Rendered by .github/workflows/release.yml and pushed to ryancurrah/homebrew-tap.
# Edit this template, not the generated cask.
cask "gimp-mcp-plugin" do
  arch arm: "arm64", intel: "x86_64"

  version "0.3.0"
  sha256 arm:   "8dc7fa4d55cffaeb93f3b82a501c24d588f1e39b05ecefe71ad7d397f2405aea",
         intel: "6c8c5499eddbc93777fb61cc41cb010977f3dce42710195f6ae3ef86adc85200"

  url "https://github.com/ryancurrah/mcp-gimp/releases/download/v#{version}/gimp-mcp-plugin_Darwin_#{arch}.tar.gz"
  name "GIMP MCP plug-in"
  desc "GIMP 3 plug-in exposing GIMP to the mcp-gimp MCP server"
  homepage "https://github.com/ryancurrah/mcp-gimp"

  livecheck do
    skip "Auto-generated on release."
  end

  # GIMP's per-user plug-ins directory is named after its major.minor version
  # and a fresh one appears on each minor upgrade, so find the newest rather
  # than assuming 3.0. Compared as versions, not strings: 3.10 beats 3.2.
  gimp_plug_ins =
    Dir.glob(File.expand_path("~/Library/Application Support/GIMP/3.*/plug-ins"))
       .max_by { |path| Gem::Version.new(path[%r{/GIMP/([\d.]+)/}, 1]) } ||
    File.expand_path("~/Library/Application Support/GIMP/3.0/plug-ins")

  # GIMP loads a plug-in from a directory named after its executable, so the
  # directory has to exist before the symlink lands in it.
  preflight do
    FileUtils.mkdir_p "#{gimp_plug_ins}/gimp-mcp-plugin"
  end

  # `binary` symlinks rather than moves, so the executable stays in the
  # Caskroom under brew's ownership and uninstall just drops the link.
  binary "gimp-mcp-plugin/gimp-mcp-plugin",
         target: "#{gimp_plug_ins}/gimp-mcp-plugin/gimp-mcp-plugin"

  postflight do
    # Unsigned download. Clear quarantine on the real files in the Caskroom;
    # xattr does not follow the symlink.
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{staged_path}/gimp-mcp-plugin"]
  end

  # Uninstall removes the symlink; the directory holding it is ours to clean.
  zap trash: "#{gimp_plug_ins}/gimp-mcp-plugin"

  caveats <<~EOS
    Restart GIMP, then run Tools > MCP > Start MCP Server.

    Linked into:
      #{gimp_plug_ins}/gimp-mcp-plugin

    That path is named after GIMP's major.minor version, so it moves when GIMP
    is upgraded. After a GIMP minor upgrade, re-link the plug-in:
      brew reinstall --cask ryancurrah/tap/gimp-mcp-plugin

    The plug-in is linked against /Applications/GIMP.app. If GIMP lives
    elsewhere, build it from source instead.
  EOS
end
