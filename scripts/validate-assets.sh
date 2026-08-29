#!/bin/zsh

set -euo pipefail

project_root="${0:A:h:h}"
manifest="$project_root/artwork/manifest.json"
pack_dir="$project_root/BenchBitsStickerPack/Stickers.xcstickers/Bench Bits.stickerpack"
messages_icon_dir="$project_root/BenchBitsStickerPack/Stickers.xcstickers/iMessage App Icon.stickersiconset"
app_icon_dir="$project_root/BenchBits/Assets.xcassets/AppIcon.appiconset"
expected_count="$(jq -r '.stickers | length' "$manifest")"
shipping_pixels="$(jq -r '.pack.shippingPixels' "$manifest")"
maximum_bytes="$(jq -r '.pack.maximumBytes' "$manifest")"

failures=0

command -v jq >/dev/null 2>&1 || {
  print -u2 -- "FAIL: jq is required"
  exit 1
}
command -v sips >/dev/null 2>&1 || {
  print -u2 -- "FAIL: sips is required"
  exit 1
}
command -v ffprobe >/dev/null 2>&1 || {
  print -u2 -- "FAIL: ffprobe is required for genuine-alpha validation"
  exit 1
}

fail() {
  print -u2 -- "FAIL: $1"
  failures=$((failures + 1))
}

image_property() {
  local image_path="$1"
  local property="$2"
  sips -g "$property" "$image_path" 2>/dev/null | awk -F': ' -v key="$property" '$1 ~ key {print $2}'
}

while IFS= read -r json_file; do
  jq empty "$json_file" >/dev/null || fail "Invalid JSON: $json_file"
done < <(find "$project_root" -name Contents.json -type f -print)

actual_count="$(find "$pack_dir" -maxdepth 1 -type d -name '*.sticker' | wc -l | tr -d ' ')"
[[ "$actual_count" == "$expected_count" ]] || fail "Expected $expected_count sticker folders; found $actual_count"

shipping_png_count="$(find "$pack_dir" -type f -name '*.png' | wc -l | tr -d ' ')"
[[ "$shipping_png_count" == "$expected_count" ]] || \
  fail "Expected exactly $expected_count shipping PNG files; found $shipping_png_count"

while IFS=$'\t' read -r order slug; do
  sticker_dir="$pack_dir/$(printf '%02d' "$order")-$slug.sticker"
  image_path="$sticker_dir/bb_$(printf '%02d' "$order")_$slug.png"
  contents_path="$sticker_dir/Contents.json"

  [[ -f "$contents_path" ]] || {
    fail "Missing metadata: $contents_path"
    continue
  }
  [[ -f "$image_path" ]] || {
    fail "Missing shipping image: $image_path"
    continue
  }

  width="$(image_property "$image_path" pixelWidth)"
  height="$(image_property "$image_path" pixelHeight)"
  alpha="$(image_property "$image_path" hasAlpha)"
  bytes="$(stat -f '%z' "$image_path")"

  [[ "$width" == "$shipping_pixels" && "$height" == "$shipping_pixels" ]] || \
    fail "Wrong dimensions for $image_path: ${width}x${height}"
  [[ "$alpha" == "yes" ]] || fail "No alpha channel: $image_path"
  (( bytes < maximum_bytes )) || fail "File is too large: $image_path ($bytes bytes)"

  alpha_range="$(ffprobe -v error -f lavfi \
    -i "movie='$image_path',alphaextract,signalstats" \
    -show_entries frame_tags=lavfi.signalstats.YMIN,lavfi.signalstats.YMAX \
    -of csv=p=0 | tr -d '\r')"
  alpha_min="${alpha_range%%,*}"
  alpha_tail="${alpha_range#*,}"
  alpha_max="${alpha_tail%%,*}"
  (( alpha_min < 255 && alpha_max == 255 )) || \
    fail "Image does not contain both transparent and opaque pixels: $image_path"

  referenced_image="$(jq -r '.properties.filename' "$contents_path")"
  [[ "$referenced_image" == "${image_path:t}" ]] || \
    fail "Metadata filename mismatch in $contents_path"
  accessibility_label="$(jq -r '.properties["accessibility-label"] // empty' "$contents_path")"
  [[ -n "$accessibility_label" ]] || fail "Missing accessibility label: $contents_path"
done < <(jq -r '.stickers[] | [.order, .slug] | @tsv' "$manifest")

icon_specs=(
  "iPhone-settings-29pt@2x.png:58:58"
  "iPhone-settings-29pt@3x.png:87:87"
  "Messages-iPhone-60x45pt@2x.png:120:90"
  "Messages-iPhone-60x45pt@3x.png:180:135"
  "iPad-settings-29pt@2x.png:58:58"
  "Messages-iPad-67x50pt@2x.png:134:100"
  "Messages-iPad-Pro-74x55pt@2x.png:148:110"
  "Messages-27x20pt@2x.png:54:40"
  "Messages-27x20pt@3x.png:81:60"
  "Messages-32x24pt@2x.png:64:48"
  "Messages-32x24pt@3x.png:96:72"
  "Messages-App-Store-1024x768.png:1024:768"
)

for spec in "${icon_specs[@]}"; do
  filename="${spec%%:*}"
  remainder="${spec#*:}"
  expected_width="${remainder%%:*}"
  expected_height="${remainder##*:}"
  icon_path="$messages_icon_dir/$filename"

  [[ -f "$icon_path" ]] || {
    fail "Missing Messages icon: $icon_path"
    continue
  }

  width="$(image_property "$icon_path" pixelWidth)"
  height="$(image_property "$icon_path" pixelHeight)"
  alpha="$(image_property "$icon_path" hasAlpha)"
  [[ "$width" == "$expected_width" && "$height" == "$expected_height" ]] || \
    fail "Wrong icon dimensions for $icon_path: ${width}x${height}"
  [[ "$alpha" == "no" ]] || fail "Icon contains an alpha channel: $icon_path"
done

app_icon="$app_icon_dir/AppIcon-1024.png"
if [[ -f "$app_icon" ]]; then
  [[ "$(image_property "$app_icon" pixelWidth)" == "1024" ]] || fail "Wrong app icon width"
  [[ "$(image_property "$app_icon" pixelHeight)" == "1024" ]] || fail "Wrong app icon height"
  [[ "$(image_property "$app_icon" hasAlpha)" == "no" ]] || fail "App icon contains an alpha channel"
else
  fail "Missing app icon: $app_icon"
fi

pack_metadata_count="$(jq -r '.stickers | length' "$pack_dir/Contents.json")"
[[ "$pack_metadata_count" == "$expected_count" ]] || fail "Sticker pack metadata lists $pack_metadata_count items"

expected_order="$(jq -r '.stickers[] | "\(.order | tostring | if length == 1 then "0" + . else . end)-\(.slug).sticker"' "$manifest")"
actual_order="$(jq -r '.stickers[].filename' "$pack_dir/Contents.json")"
[[ "$actual_order" == "$expected_order" ]] || fail "Sticker pack order does not match artwork/manifest.json"

messages_icon_metadata_count="$(jq -r '.images | length' "$messages_icon_dir/Contents.json")"
[[ "$messages_icon_metadata_count" == "${#icon_specs[@]}" ]] || \
  fail "Messages icon metadata lists $messages_icon_metadata_count items"

app_icon_metadata_count="$(jq -r '.images | length' "$app_icon_dir/Contents.json")"
[[ "$app_icon_metadata_count" == "1" ]] || fail "App icon metadata must list one modern universal icon"

messages_icon_file_count="$(find "$messages_icon_dir" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')"
[[ "$messages_icon_file_count" == "${#icon_specs[@]}" ]] || \
  fail "Expected exactly ${#icon_specs[@]} Messages icon PNG files; found $messages_icon_file_count"

app_icon_file_count="$(find "$app_icon_dir" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')"
[[ "$app_icon_file_count" == "1" ]] || fail "Expected exactly one app icon PNG; found $app_icon_file_count"

if (( failures > 0 )); then
  print -u2 -- "Asset validation failed with $failures issue(s)."
  exit 1
fi

print -- "Asset validation passed: $expected_count stickers and ${#icon_specs[@]} Messages icons."
