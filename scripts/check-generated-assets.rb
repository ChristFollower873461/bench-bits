#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"

root = File.expand_path("..", __dir__)
generated_roots = [
  File.join(root, "BenchBits", "Assets.xcassets", "AppIcon.appiconset"),
  File.join(root, "BenchBitsStickerPack", "Stickers.xcstickers", "Bench Bits.stickerpack"),
  File.join(root, "BenchBitsStickerPack", "Stickers.xcstickers", "iMessage App Icon.stickersiconset")
].freeze

def tree_digest(root, paths)
  digest = Digest::SHA256.new
  files = paths.flat_map do |path|
    Dir.glob(File.join(path, "**", "*"), File::FNM_DOTMATCH).select { |entry| File.file?(entry) }
  end.sort

  files.each do |path|
    digest << path.delete_prefix(root)
    digest << "\0"
    digest << File.binread(path)
    digest << "\0"
  end

  digest.hexdigest
end

before = tree_digest(root, generated_roots)
abort("Asset generation failed") unless system("ruby", File.join(root, "scripts", "build-assets.rb"))
after = tree_digest(root, generated_roots)

abort(<<~MESSAGE) unless before == after
  Generated assets were stale and have been refreshed.
  Review the changes, then rerun QA; a clean run must not rewrite generated output.
MESSAGE

puts("Generated asset catalogs were already current.")
