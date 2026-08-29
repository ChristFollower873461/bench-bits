#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

root = File.expand_path("..", __dir__)
manifest = JSON.parse(File.read(File.join(root, "artwork", "manifest.json")))
pack_dir = File.join(root, "BenchBitsStickerPack", "Stickers.xcstickers", "Bench Bits.stickerpack")
output = File.join(root, "docs", "bench-bits-contact-sheet.png")
allow_missing = ARGV.include?("--allow-missing")

assets = manifest.fetch("stickers").sort_by { |item| item.fetch("order") }.each_with_object([]) do |item, paths|
  order = item.fetch("order")
  slug = item.fetch("slug")
  path = File.join(
    pack_dir,
    format("%02d-%s.sticker", order, slug),
    format("bb_%02d_%s.png", order, slug)
  )

  if File.exist?(path)
    paths << path
  elsif allow_missing
    warn("Skipping missing sticker: #{path}")
  else
    abort("Missing sticker: #{path}")
  end
end

abort("No shipping stickers found") if assets.empty?
abort("ffmpeg is required to build the contact sheet") unless system("command", "-v", "ffmpeg", out: File::NULL)

columns = 5
panel = 440
rows = (assets.length.to_f / columns).ceil
arguments = assets.flat_map { |path| ["-i", path] }
filters = []

assets.each_index do |index|
  filters << "color=c=0x172033:s=#{panel}x#{panel}:d=1[bg#{index}]"
  filters << "[#{index}:v]scale=408:408[sticker#{index}]"
  filters << "[bg#{index}][sticker#{index}]overlay=16:16:format=auto[panel#{index}]"
end

layout = assets.each_index.map do |index|
  column = index % columns
  row = index / columns
  "#{column * panel}_#{row * panel}"
end.join("|")

panel_inputs = assets.each_index.map { |index| "[panel#{index}]" }.join
filters << "#{panel_inputs}xstack=inputs=#{assets.length}:layout=#{layout}:fill=0x172033,format=rgb24[out]"

command = [
  "ffmpeg", "-y", "-loglevel", "error",
  *arguments,
  "-filter_complex", filters.join(";"),
  "-map", "[out]",
  "-frames:v", "1",
  output
]

abort("ffmpeg failed to create the contact sheet") unless system(*command)

puts("Created #{output} (#{columns} columns × #{rows} rows).")
