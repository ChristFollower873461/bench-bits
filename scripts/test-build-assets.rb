#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "rbconfig"
require "tmpdir"

BUILDER = File.expand_path("build-assets.rb", __dir__)
GENERATED_ROOTS = [
  "BenchBits/Assets.xcassets/AppIcon.appiconset",
  "BenchBitsStickerPack/Stickers.xcstickers/Bench Bits.stickerpack",
  "BenchBitsStickerPack/Stickers.xcstickers/iMessage App Icon.stickersiconset"
].freeze
MASTER_PATHS = [
  "artwork/masters/first.png",
  "artwork/masters/second.png",
  "artwork/icon-master/bench-bits-icon.png"
].freeze

def write_fixture(root, relative, content)
  path = File.join(root, relative)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
end

def generated_snapshot(root)
  GENERATED_ROOTS.flat_map do |relative|
    Dir.glob(File.join(root, relative, "**", "*"))
  end.select { |path| File.file?(path) }.sort.each_with_object({}) do |path, result|
    result[path.delete_prefix(root)] = Digest::SHA256.file(path).hexdigest
  end
end

def exercise_builder(missing, arguments = [])
  Dir.mktmpdir("bench-asset-preflight-test") do |root|
    FileUtils.mkdir_p(File.join(root, "scripts"))
    FileUtils.cp(BUILDER, File.join(root, "scripts/build-assets.rb"))
    manifest = {
      "pack" => {"shippingPixels" => 408, "maximumBytes" => 500_000, "gridSize" => "regular"},
      "stickers" => [
        {"order" => 1, "slug" => "first", "master" => "first.png", "accessibilityLabel" => "First"},
        {"order" => 2, "slug" => "second", "master" => "second.png", "accessibilityLabel" => "Second"}
      ]
    }
    write_fixture(root, "artwork/manifest.json", JSON.generate(manifest))
    (MASTER_PATHS - missing).each { |path| write_fixture(root, path, "synthetic master fixture") }
    GENERATED_ROOTS.each { |path| write_fixture(root, "#{path}/Contents.json", "preserved metadata") }
    %w[first second].each_with_index do |slug, index|
      relative = format("%s/%02d-%s.sticker", GENERATED_ROOTS[1], index + 1, slug)
      write_fixture(root, "#{relative}/Contents.json", "preserved sticker metadata")
      write_fixture(root, format("%s/bb_%02d_%s.png", relative, index + 1, slug), "preserved shipping fixture")
    end
    write_fixture(root, "#{GENERATED_ROOTS[0]}/AppIcon-1024.png", "preserved app icon fixture")
    write_fixture(root, "#{GENERATED_ROOTS[2]}/Messages-App-Store-1024x768.png", "preserved Messages icon fixture")

    # A conversion attempt must never reach real artwork tools in these tests.
    # The all-present case intentionally stops at this stub after the preflight.
    tool = File.join(root, "bin/sips")
    write_fixture(root, "bin/sips", "#!/bin/sh\nprintf 'called\\n' >> \"$BENCH_TEST_SIPS_LOG\"\nexit 87\n")
    File.chmod(0o755, tool)
    log = File.join(root, "sips-calls.log")
    before = generated_snapshot(root)
    stdout, stderr, status = Open3.capture3(
      {"PATH" => "#{File.dirname(tool)}#{File::PATH_SEPARATOR}#{ENV.fetch('PATH', '')}", "BENCH_TEST_SIPS_LOG" => log},
      RbConfig.ruby, File.join(root, "scripts/build-assets.rb"), *arguments
    )
    yield({stdout: stdout, stderr: stderr, status: status, converted: File.exist?(log),
           unchanged: before == generated_snapshot(root), root: root})
  end
end

cases = [
  ["missing sticker master preserves every generated file", [MASTER_PATHS[1]]],
  ["missing icon master preserves every generated file", [MASTER_PATHS[2]]],
  ["all missing masters are reported before any conversion", MASTER_PATHS]
]
failures = []
cases.each do |name, missing|
  exercise_builder(missing) do |result|
    problems = []
    problems << "generation unexpectedly succeeded" if result[:status].success?
    problems << "an image conversion was attempted" if result[:converted]
    problems << "generated output was modified" unless result[:unchanged]
    missing.each do |path|
      problems << "missing diagnostic for #{path}" unless result[:stderr].include?(File.join(result[:root], path))
    end
    if problems.empty?
      puts("PASS: #{name}")
    else
      failures << "#{name}: #{problems.join('; ')}"
    end
  end
end

exercise_builder([]) do |result|
  if result[:converted] && !result[:status].success? && result[:stderr].include?("Command failed: sips")
    puts("PASS: complete inputs reach the converter")
  else
    failures << "complete inputs did not reach the controlled converter failure"
  end
end

exercise_builder(MASTER_PATHS, ["--allow-missing"]) do |result|
  if result[:status].success? && !result[:converted] && result[:stderr].include?("Missing 3 master assets") && result[:stdout].include?("Built 0 of 2 stickers.")
    puts("PASS: explicit --allow-missing retains partial generation")
  else
    failures << "explicit --allow-missing behavior changed"
  end
end

abort(failures.map { |failure| "FAIL: #{failure}" }.join("\n")) unless failures.empty?
puts("Asset-builder preflight regression checks passed (5 cases).")
