# Bench Bits release checklist

## Product decisions

- [ ] Clear the working title “Bench Bits” for App Store, web, and trademark use; rename before App ID registration if needed.
- [ ] Confirm the public publisher is Dream Manifold Technologies LLC.
- [ ] Confirm free launch and no purchases, ads, analytics, accounts, or network access.
- [ ] Approve the final display name, subtitle, description, keywords, Stickers category/subcategory, age rating, SKU, price, and availability.

## Identity and signing

- [ ] Enroll or verify the Dream Manifold Technologies Apple Developer account.
- [ ] Replace the provisional `com.dreammanifold.benchbits` identifiers if the final product name changes.
- [ ] Select the correct development team and enable automatic signing.
- [ ] Create the matching App Store Connect record.

## Build and runtime QA

- [ ] Install stable Xcode 26 or newer and an iOS platform, then run `./scripts/qa.sh` with no skipped build steps.
- [ ] Test the pack on current iPhone and iPad Simulators.
- [ ] Confirm launch and installation behavior at the iOS/iPadOS 15.0 minimum deployment target on available compatible hardware or a supported runtime.
- [ ] Test on a physical iPhone and a physical iPad: tap/send, peel, resize, rotate, order, light/dark/photo contrast, transparent edges, and every icon location.
- [ ] With VoiceOver enabled on both device families, confirm all 20 compiled stickers announce the intended literal labels in pack order.
- [ ] Verify the host does not expose unintended UI and the pack appears consistently after install/update.
- [ ] Create a signed Release archive and inspect Organizer validation results.
- [ ] Upload to TestFlight and retest the processed build before review.

## Store materials and policy

- [ ] Publish a support URL and a privacy-policy URL. The shipped binary declares no tracking, data collection, or required-reason APIs; keep the public policy and App Store privacy answers consistent with that fact.
- [ ] Prepare polished fictional Messages conversations—no real names, accounts, phone numbers, or private customer content.
- [ ] Supply the current required iPhone screenshot set and, because the target supports iPad, the current required 13-inch iPad screenshot set. Confirm exact wells in App Store Connect at submission time.
- [ ] Verify host 1024×1024 and Messages 1024×768 marketing icons after App Store processing.
- [ ] State that these are original stickers, not official emoji, and avoid Apple endorsement language.
- [ ] Complete App Review contact information and review notes.

## Final approval

- [ ] Approve the 20-sticker contact sheet and icon master.
- [ ] Establish and commit the intended source-control baseline.
- [ ] Submit through App Store Connect only after the signed TestFlight build passes the runtime checklist.
