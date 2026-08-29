#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "tmpdir"

root = File.expand_path("..", __dir__)
toolchain = JSON.parse(File.read(File.join(root, "toolchain.json")))
required_xcodegen = toolchain.fetch("xcodegen")
version_output = `xcodegen --version 2>&1`
installed_xcodegen = version_output[/\d+\.\d+\.\d+/]

abort("XcodeGen #{required_xcodegen} is required; found #{installed_xcodegen || "none"}") unless installed_xcodegen == required_xcodegen

comparisons = [
  "BenchBits.xcodeproj/project.pbxproj",
  "BenchBits.xcodeproj/xcshareddata/xcschemes/BenchBits.xcscheme",
  "BenchBits/Info.plist",
  "BenchBitsStickerPack/Info.plist"
].freeze

Dir.mktmpdir("bench-bits-xcodegen") do |temporary_root|
  FileUtils.cp(File.join(root, "project.yml"), temporary_root)
  FileUtils.cp_r(File.join(root, "BenchBits"), temporary_root)
  FileUtils.cp_r(File.join(root, "BenchBitsStickerPack"), temporary_root)

  generated = system(
    "xcodegen", "generate", "--quiet",
    "--spec", File.join(temporary_root, "project.yml"),
    "--project", temporary_root,
    "--project-root", temporary_root
  )
  abort("Temporary XcodeGen generation failed") unless generated

  stale = comparisons.reject do |relative_path|
    FileUtils.compare_file(
      File.join(root, relative_path),
      File.join(temporary_root, relative_path)
    )
  end

  unless stale.empty?
    abort("Generated Xcode files are stale: #{stale.join(", ")}. Run `xcodegen generate --spec project.yml`.")
  end
end

puts("Generated Xcode project and Info plists match project.yml using XcodeGen #{required_xcodegen}.")
