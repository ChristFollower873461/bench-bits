# Bench Bits v0.1 implementation brief

## Outcome

Ship a maintainable, original, standalone iMessage sticker-pack project inspired by electronic components—not by Apple’s emoji rendering. Preserve high-resolution masters so the artwork can later be adapted for small physical die-cut stickers without rebuilding the set.

## Acceptance criteria

1. The project contains a Messages host and embedded no-code sticker-pack extension.
2. The launch pack contains the 20 items in `artwork/manifest.json`, in that order.
3. Every shipping sticker is a square 408×408 PNG with a genuine alpha channel and a file size below 500 KB.
4. Every sticker has a literal, useful VoiceOver description.
5. App and Messages icons are complete, opaque, full-bleed, and derived from one preserved icon master.
6. No asset contains words, logos, manufacturer marks, Apple UI, Apple emoji, branded board layouts, or copied reference composition.
7. XcodeGen can recreate the project deterministically from `project.yml`.
8. The repo includes dependency-light structural and image checks plus a QA note that states any unverified release gates.

## Non-goals for v0.1

- No custom sticker browser, animation, purchases, telemetry, accounts, ads, or network access.
- No App Store submission until the name, bundle identifiers, support URL, privacy URL, developer team, screenshots, and on-device behavior are approved.
- No claim that generated masters are production-ready for large-format printing; physical exports require a separate print-size and bleed review.

## Originality guardrails

- Generic components only; no Apple, Arduino, Raspberry Pi, vendor, certification, or part-number marks.
- Workbench Pop remains graphically illustrated rather than Apple-style polished emoji realism.
- No keyboard, Messages UI, or arrangement copied from the source post.
- Prompts and generated masters are retained for provenance and consistent iteration.

## Release verification still required

- Open and regenerate with stable Xcode 26 or newer.
- Confirm signing with the correct Dream Manifold Technologies Apple Developer team.
- Test tap-to-send, peel, resize, rotate, pack order, transparency, and readability on current iPhone and iPad Simulators plus physical iPhone and iPad devices.
- Enable VoiceOver on both device families and verify all 20 compiled labels and their order in Messages.
- Because the target supports iPad, prepare and verify the current required 13-inch iPad App Store screenshot set as well as the iPhone set.
- Run TestFlight before App Review submission.
