#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
MANIFEST_PATH = File.join(ROOT, "artwork", "manifest.json")
MASTERS_DIR = File.join(ROOT, "artwork", "masters")
ICON_MASTER = File.join(ROOT, "artwork", "icon-master", "bench-bits-icon.png")
PACK_DIR = File.join(
  ROOT,
  "BenchBitsStickerPack",
  "Stickers.xcstickers",
  "Bench Bits.stickerpack"
)
MESSAGES_ICON_DIR = File.join(
  ROOT,
  "BenchBitsStickerPack",
  "Stickers.xcstickers",
  "iMessage App Icon.stickersiconset"
)
APP_ICON_DIR = File.join(ROOT, "BenchBits", "Assets.xcassets", "AppIcon.appiconset")
LOCK_PATH = File.join(ROOT, "build", ".asset-build.lock")

ALLOW_MISSING = ARGV.include?("--allow-missing")

FileUtils.mkdir_p(File.dirname(LOCK_PATH))
asset_build_lock = File.open(LOCK_PATH, File::RDWR | File::CREAT, 0o644)
abort("Unable to acquire the asset-build lock") unless asset_build_lock.flock(File::LOCK_EX)

def write_json(path, object)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, JSON.pretty_generate(object) + "\n")
end

def run!(*command)
  return if system(*command, out: File::NULL)

  abort("Command failed: #{command.join(" ")}")
end

def image_properties(path)
  output = IO.popen(
    ["sips", "-g", "pixelWidth", "-g", "pixelHeight", "-g", "hasAlpha", path],
    err: File::NULL,
    &:read
  )

  {
    width: output[/pixelWidth:\s+(\d+)/, 1]&.to_i,
    height: output[/pixelHeight:\s+(\d+)/, 1]&.to_i,
    has_alpha: output[/hasAlpha:\s+(\w+)/, 1]
  }
end

def resize_png(source, destination, width, height)
  FileUtils.mkdir_p(File.dirname(destination))
  FileUtils.rm_f(destination)
  run!("sips", "-z", height.to_s, width.to_s, source, "--out", destination)
end

manifest = JSON.parse(File.read(MANIFEST_PATH))
pack = manifest.fetch("pack")
stickers = manifest.fetch("stickers").sort_by { |item| item.fetch("order") }
shipping_pixels = pack.fetch("shippingPixels")
maximum_bytes = pack.fetch("maximumBytes")
missing = []

pack_entries = stickers.map do |item|
  order = item.fetch("order")
  slug = item.fetch("slug")
  folder_name = format("%02d-%s.sticker", order, slug)
  image_name = format("bb_%02d_%s.png", order, slug)
  sticker_dir = File.join(PACK_DIR, folder_name)
  master_path = File.join(MASTERS_DIR, item.fetch("master"))
  shipping_path = File.join(sticker_dir, image_name)

  FileUtils.mkdir_p(sticker_dir)
  Dir.glob(File.join(sticker_dir, "*.png")).each do |existing_png|
    FileUtils.rm_f(existing_png) unless File.basename(existing_png) == image_name
  end
  write_json(
    File.join(sticker_dir, "Contents.json"),
    {
      "info" => {"author" => "xcode", "version" => 1},
      "properties" => {
        "accessibility-label" => item.fetch("accessibilityLabel"),
        "filename" => image_name
      }
    }
  )

  if File.exist?(master_path)
    resize_png(master_path, shipping_path, shipping_pixels, shipping_pixels)
    properties = image_properties(shipping_path)
    unless properties[:width] == shipping_pixels && properties[:height] == shipping_pixels
      abort("Unexpected dimensions for #{shipping_path}: #{properties.inspect}")
    end
    abort("Sticker lost its alpha channel: #{shipping_path}") unless properties[:has_alpha] == "yes"
    abort("Sticker exceeds #{maximum_bytes} bytes: #{shipping_path}") if File.size(shipping_path) >= maximum_bytes
  else
    missing << master_path
    FileUtils.rm_f(shipping_path)
  end

  {"filename" => folder_name}
end

write_json(
  File.join(PACK_DIR, "Contents.json"),
  {
    "info" => {"author" => "xcode", "version" => 1},
    "properties" => {"grid-size" => pack.fetch("gridSize")},
    "stickers" => pack_entries
  }
)

messages_icon_slots = [
  ["iPhone-settings-29pt@2x.png", "iphone", "29x29", "2x", nil, 58, 58, :square],
  ["iPhone-settings-29pt@3x.png", "iphone", "29x29", "3x", nil, 87, 87, :square],
  ["Messages-iPhone-60x45pt@2x.png", "iphone", "60x45", "2x", nil, 120, 90, :wide],
  ["Messages-iPhone-60x45pt@3x.png", "iphone", "60x45", "3x", nil, 180, 135, :wide],
  ["iPad-settings-29pt@2x.png", "ipad", "29x29", "2x", nil, 58, 58, :square],
  ["Messages-iPad-67x50pt@2x.png", "ipad", "67x50", "2x", nil, 134, 100, :wide],
  ["Messages-iPad-Pro-74x55pt@2x.png", "ipad", "74x55", "2x", nil, 148, 110, :wide],
  ["Messages-27x20pt@2x.png", "universal", "27x20", "2x", "ios", 54, 40, :wide],
  ["Messages-27x20pt@3x.png", "universal", "27x20", "3x", "ios", 81, 60, :wide],
  ["Messages-32x24pt@2x.png", "universal", "32x24", "2x", "ios", 64, 48, :wide],
  ["Messages-32x24pt@3x.png", "universal", "32x24", "3x", "ios", 96, 72, :wide],
  ["Messages-App-Store-1024x768.png", "ios-marketing", "1024x768", "1x", "ios", 1024, 768, :wide]
].freeze

if File.exist?(ICON_MASTER)
  FileUtils.mkdir_p(MESSAGES_ICON_DIR)
  FileUtils.mkdir_p(APP_ICON_DIR)
  # The host AppIcon catalog owns the square 1024 marketing icon. The Messages
  # icon schema has only the 1024×768 marketing slot.
  FileUtils.rm_f(File.join(MESSAGES_ICON_DIR, "App-Store-1024x1024.png"))
  expected_messages_icons = messages_icon_slots.map(&:first)
  Dir.glob(File.join(MESSAGES_ICON_DIR, "*.png")).each do |existing_png|
    FileUtils.rm_f(existing_png) unless expected_messages_icons.include?(File.basename(existing_png))
  end
  Dir.glob(File.join(APP_ICON_DIR, "*.png")).each do |existing_png|
    FileUtils.rm_f(existing_png) unless File.basename(existing_png) == "AppIcon-1024.png"
  end

  Dir.mktmpdir("bench-bits-icons") do |temporary_dir|
    jpeg = File.join(temporary_dir, "opaque.jpg")
    opaque_source = File.join(temporary_dir, "opaque-source.png")
    opaque_square = File.join(temporary_dir, "opaque-square.png")
    opaque_wide = File.join(temporary_dir, "opaque-wide.png")

    # A JPEG round-trip guarantees the shipping icon files contain no alpha channel.
    run!("sips", "-s", "format", "jpeg", "-s", "formatOptions", "100", ICON_MASTER, "--out", jpeg)
    run!("sips", "-s", "format", "png", jpeg, "--out", opaque_source)
    # Normalize to 1024 square before taking the 1024×768 Messages crop.
    # Cropping the larger generated master directly would remove too much vertically.
    resize_png(opaque_source, opaque_square, 1024, 1024)
    run!("sips", "--cropToHeightWidth", "768", "1024", opaque_square, "--out", opaque_wide)

    messages_images = messages_icon_slots.map do |filename, idiom, size, scale, platform, width, height, shape|
      source = shape == :square ? opaque_square : opaque_wide
      resize_png(source, File.join(MESSAGES_ICON_DIR, filename), width, height)

      entry = {"filename" => filename, "idiom" => idiom, "scale" => scale, "size" => size}
      entry["platform"] = platform if platform
      entry
    end

    resize_png(opaque_square, File.join(APP_ICON_DIR, "AppIcon-1024.png"), 1024, 1024)

    write_json(
      File.join(MESSAGES_ICON_DIR, "Contents.json"),
      {"images" => messages_images, "info" => {"author" => "xcode", "version" => 1}}
    )
    write_json(
      File.join(APP_ICON_DIR, "Contents.json"),
      {
        "images" => [
          {
            "filename" => "AppIcon-1024.png",
            "idiom" => "universal",
            "platform" => "ios",
            "scale" => "1x",
            "size" => "1024x1024"
          }
        ],
        "info" => {"author" => "xcode", "version" => 1}
      }
    )
  end
else
  missing << ICON_MASTER
end

if missing.any?
  message = "Missing #{missing.length} master asset#{missing.length == 1 ? "" : "s"}:\n" +
            missing.map { |path| "  - #{path}" }.join("\n")
  abort(message) unless ALLOW_MISSING
  warn(message)
end

puts("Built #{stickers.length - missing.count { |path| path.start_with?(MASTERS_DIR) }} of #{stickers.length} stickers.")
puts("Asset-catalog metadata is current.")
