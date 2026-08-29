# Bench Bits v0.1 QA note

Date: August 29, 2026

## Result

The no-code project, generated asset catalogs, 20-sticker launch set, host icon, and Messages icon set pass all checks available on this Mac. The project is structurally ready to open in Xcode. It is not release-certified yet because full Xcode and the iOS SDK are not installed on this machine.

## Commands and evidence

### `./scripts/qa.sh --allow-missing-xcode`

Passed:

- Rebuilding the generated catalogs produced no file changes.
- A temporary XcodeGen 2.46.0 recreation matched the checked-in `project.pbxproj`, shared scheme, and generated Info plists byte-for-byte.
- All 20 shipping stickers are 408×408 PNGs with an alpha channel, both transparent and opaque pixels, literal accessibility labels, correct manifest order, and file sizes below 500,000 bytes.
- Shipping sticker sizes range from 94,043 to 240,082 bytes.
- Exactly 20 shipping PNGs, one opaque 1024×1024 host icon, and 12 opaque Messages icon renditions are present; no unreferenced duplicate PNGs remain.
- The host and extension Info plists plus `PrivacyInfo.xcprivacy` pass `plutil` validation.
- The generated project contains a `com.apple.product-type.application.messages` host, an embedded `com.apple.product-type.app-extension.messages-sticker-pack` extension, and a shared host scheme.
- The no-code project targets iOS/iPadOS 15.0, the oldest deployment target supported by Xcode 26, rather than unnecessarily excluding older compatible devices.

Skipped with an explicit message:

- Debug iOS Simulator compile.
- Unsigned Release generic-device compile.

Reason: `xcode-select` points to Command Line Tools and no full Xcode/iOS SDK is installed. The default `./scripts/qa.sh` release gate fails when Xcode is absent; `--allow-missing-xcode` explicitly permits only the structural portion. When Xcode is present, the script requires version 26 or newer.

### `./scripts/make-contact-sheet.rb`

Passed. It generated `docs/bench-bits-contact-sheet.png`, and the complete 5×4 sheet was visually inspected on a dark background. All subjects are readable, stylistically coherent, uncropped, and free of words, logos, faces, manufacturer marks, Apple UI, and copied keyboard composition.

The app icon’s initial 4:3 crop was rejected because it clipped the LED. The master and crop pipeline were corrected; the final 1024×768 marketing icon and smallest 27×20@3x rendition both retain the complete hero artwork.

## Remaining gaps

- Open with stable Xcode 26 or newer and run the two compile checks in `scripts/qa.sh`.
- Select the correct Apple Developer team and register final bundle identifiers.
- Test in Messages on iPhone and iPad, including tap-to-send, peel, resize, rotate, pack order, transparency, light/dark/photo backgrounds, and icon rendering.
- Create and validate a signed archive, then test the processed build through TestFlight.
- Finish the product decisions and App Store materials in `docs/release-checklist.md`.
- This new project directory is currently untracked in the enclosing workspace Git repository; establish the intended repository/baseline before release work.
