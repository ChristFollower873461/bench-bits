#!/bin/zsh

set -euo pipefail

project_root="${0:A:h:h}"
cd "$project_root"
allow_missing_xcode=false
[[ "${1:-}" == "--allow-missing-xcode" ]] && allow_missing_xcode=true

./scripts/check-generated-assets.rb
./scripts/check-generated-project.rb
./scripts/validate-assets.sh

plutil -lint BenchBits/Info.plist BenchBitsStickerPack/Info.plist BenchBits/PrivacyInfo.xcprivacy
rg -q 'com.apple.product-type.application.messages' BenchBits.xcodeproj/project.pbxproj
rg -q 'com.apple.product-type.app-extension.messages-sticker-pack' BenchBits.xcodeproj/project.pbxproj
rg -q 'BenchBitsStickerPack.appex in Embed Foundation Extensions' BenchBits.xcodeproj/project.pbxproj

if xcodebuild -version >/dev/null 2>&1; then
  xcode_major="$(xcodebuild -version | awk '/Xcode/{split($2, parts, "."); print parts[1]}')"
  required_xcode_major="$(jq -r '.xcodeMinimum | split(".")[0]' toolchain.json)"
  (( xcode_major >= required_xcode_major )) || {
    print -u2 -- "FAIL: Xcode $required_xcode_major or newer is required; found Xcode $xcode_major."
    exit 1
  }

  xcodebuild \
    -project BenchBits.xcodeproj \
    -scheme BenchBits \
    -configuration Debug \
    -destination 'generic/platform=iOS Simulator' \
    CODE_SIGNING_ALLOWED=NO \
    clean build

  xcodebuild \
    -project BenchBits.xcodeproj \
    -scheme BenchBits \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    CODE_SIGNING_ALLOWED=NO \
    clean build
else
  if [[ "$allow_missing_xcode" == true ]]; then
    print -u2 -- 'SKIP: Selected developer tools cannot run xcodebuild; Debug Simulator and unsigned Release device builds were not run.'
  else
    print -u2 -- 'FAIL: A usable Xcode/iOS SDK selection is required. Set DEVELOPER_DIR or select Xcode; use --allow-missing-xcode only for structural QA.'
    exit 1
  fi
fi

print -- 'Bench Bits structural QA completed.'
