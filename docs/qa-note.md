# Bench Bits v0.1 QA note

Initial record: August 29, 2026. Current checkpoint: September 26, 2026.

## Current checkpoint — 2026-09-26

The launch-configuration warning is resolved. [PR #2](https://github.com/ChristFollower873461/bench-bits/pull/2) added the host launch-screen configuration, and adopted main `9d77b36c12db8ee2d994d57dbd399a49a703849b` has a [passing Quality run](https://github.com/ChristFollower873461/bench-bits/actions/runs/36242142267) with zero annotations. The strict generated-asset/project checks and unsigned builds remain accepted.

A separate Debug Simulator build using Xcode 27.0 (27A266a) completed with zero warnings. Its source tree matches that adopted main commit. Bounded runtime checks on iOS/iPadOS 26.5 (23F77) established:

- The installed iPhone 17 Pro and iPad Pro 13-inch M5 copies match all 38 files of the reviewed build, with no extra files.
- Messages discovers and renders the pack on both families. All 20 illustrations appear in source order across the settled iPad views.
- An unsent motor preview on iPhone and transistor preview on iPad were inserted and removed. The two sampled accessible descriptions match source.
- All 20 compiled descriptions and their order match source. This metadata check and the sampled descriptions do not establish audible VoiceOver acceptance.

The source/build/installed-file comparison and retained rendering evidence passed independent review. Both task simulators were shut down after the check. No message was sent, real device installed, account signed in, or store upload performed.

The recorded runtime result has SHA-256 `20836e72ecbac8852bd5684e1ee3bed68d4b1cbd895955c857da525ce99d91a3`; its separate independent review has SHA-256 `bd72914b9e977c40124d76b3b54e0aff62ee43dfa46ba8048cfe3e20ac479c88`. These are the September 26 `RUNTIME-RESULT.json` and `independent-runtime-review.json` receipts, respectively.

Still required before release:

- Current iOS/iPadOS and minimum iOS/iPadOS 15.0 runtime coverage; this checkpoint exercised 26.5 only.
- Physical iPhone and iPad Messages checks, including send, peel, resize, rotate, light/dark/photo contrast, transparent edges, and icon locations.
- Audible VoiceOver for all 20 stickers on both device families, consistent install/update discovery, and checks for unintended host UI.
- Owner decisions on source/artwork reuse, title, publisher, final bundle identifiers, and signing identity.
- Signed archive validation, processed TestFlight testing, and the applicable store materials and acceptance in [the release checklist](release-checklist.md).

The dated entries below retain earlier findings. Their missing-toolchain, pending-build, and launch-warning statements describe those earlier checkpoints, not current blockers.

## Initial result — 2026-08-29

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

## Repository baseline update — 2026-09-05

The source is now tracked in the [public Bench Bits repository](https://github.com/ChristFollower873461/bench-bits), and [v0.1.0](https://github.com/ChristFollower873461/bench-bits/releases/tag/v0.1.0) is a published source release. This resolves the earlier repository-setup gap; the compile, device, signing, and distribution gaps above remain open.

On September 5, `./scripts/qa.sh --allow-missing-xcode` passed all structural checks again with XcodeGen 2.46.0; both compile checks were explicitly skipped because this Mac still uses Command Line Tools. The new Quality workflow runs the default `./scripts/qa.sh` on a macOS 26 runner with Xcode 26.6 and the exact XcodeGen release. Missing Xcode or failed compilation fails CI; it does not use the structural-only flag. Hosted compile results must be recorded separately from this local result.

## Icon reproducibility repair — 2026-09-05

The first hosted QA run failed the exact generated-asset drift check before reaching either compile. A [diagnostic rerun](https://github.com/ChristFollower873461/bench-bits/actions/runs/33964344111) isolated changes to the host icon and all 12 Messages icons. All 20 stickers and all catalog JSON remained unchanged. The icons differed in decoded pixels by up to four channel levels; their PNG metadata chunks were identical. Both machines reported macOS 26.6.2 and sips-316, so this was not explained by a different macOS version or harmless PNG metadata.

The icon-only generator path unnecessarily converted the already opaque PNG master through JPEG and back before resizing. It now resizes the original PNG directly and explicitly rejects an icon master with an alpha channel. The 13 icons were deliberately regenerated; the artwork master, crop geometry, catalog metadata and exact byte drift gate remain unchanged. This removes the unnecessary lossy intermediate without introducing a pixel tolerance.

Two consecutive local `./scripts/qa.sh --allow-missing-xcode` runs passed after regeneration, including exact asset/project reproduction and all existing image/plist checks. A synthetic alpha-bearing master was rejected as intended. The regenerated host and smallest Messages icon retain the same composition in visual review. Both local compile checks were explicitly skipped; a new hosted default QA run must still establish cross-machine reproduction and successful unsigned compilation.

## Host icon schema and unsigned compilation — 2026-09-05

The [next hosted run](https://github.com/ChristFollower873461/bench-bits/actions/runs/33964834373) passed exact asset/project reproduction and all image/plist checks. Its Debug Simulator build then failed because `actool` found no applicable content in the host `AppIcon` catalog. The sticker extension's assets had compiled successfully.

Xcode 26.6 is available locally at `/Applications/Xcode.app`, with iOS and iOS Simulator 26.5 SDKs. The earlier September 5 structural-only runs used the Command Line Tools selection; that selection did not establish that Xcode was absent. The August 29 entries above remain historical records.

A disposable local comparison used the same host-app `actool` options and identical PNG bytes. The existing universal iOS 1024×1024 entry with `scale: 1x` reproduced the failure. Removing only that scale field compiled successfully. The generator and checked-in catalog now omit it, matching Xcode's single-size iOS icon template. Apple documents automatic variant generation from one 1024×1024 image in [its app-icon guide](https://developer.apple.com/documentation/xcode/configuring-your-app-icon/).

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/qa.sh
```

This default QA command passed locally with Xcode 26.6 (17F113) and XcodeGen 2.46.0:

- Exact generated-asset and project reproduction, all 20 sticker/13 icon checks, and plist validation passed.
- Debug generic iOS Simulator build passed.
- Unsigned Release generic iOS-device build passed.
- All 33 generated PNGs remained byte-for-byte unchanged by the metadata correction and QA run.

Neither compile was skipped. Both used `CODE_SIGNING_ALLOWED=NO`; no device was installed or launched, and no signing, account, archive, TestFlight, or App Store action occurred. The system-wide `xcode-select` setting remains Command Line Tools. The QA diagnostic now describes an unusable selected toolchain instead of inferring that no Xcode installation exists.

At this September 5 checkpoint, the compiler still reported a host launch-configuration/storyboard warning. The September 26 checkpoint above records its subsequent repair and bounded Simulator acceptance. Physical Messages interactions, signing, and TestFlight acceptance remain separate requirements.
