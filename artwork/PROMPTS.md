# Artwork prompt record

Mode: built-in image generation. Each first-pass subject used one generation call. Failed simulated-transparency outputs were rejected; selected assets then received a targeted transparency edit or a fresh regeneration. Shipping PNGs are mechanical 408×408 exports from the accepted workspace masters.

## Shared sticker direction

Create one original digital sticker for the Bench Bits series: **[SUBJECT]**, communicating **[MEANING]**. Use the original “Workbench Pop” style: chunky simplified but technically recognizable geometry; matte powder-coated surfaces, translucent acrylic where appropriate, brushed-metal leads; a thin deep-navy keyline; and a thick, clean warm-white die-cut sticker border. Use cobalt `#176BFF`, aqua `#27D7C4`, coral `#FF665C`, mustard `#FFC44D`, ink `#172033`, and warm white `#FFF8EB`. Add tiny hand-drawn highlight marks and at most one subtle abstract circuit-trace motif. Use a three-quarter isometric view from 25–30 degrees above, a soft upper-left key light, and a minimal lower-right contact shadow contained inside the sticker border. Center the subject at 72–80% of a square canvas with a crisp silhouette readable at 80 pixels. Communicate meaning through glow, tilt, sparks, motion, smoke, or mechanical state—never a face. Use a genuine transparent background outside the warm-white border and preserve alpha. No ground plane, scene, UI, keyboard, words, letters, numbers, logos, manufacturer marks, product branding, Apple emoji styling, glossy photorealism, or copied reference composition. Output a square high-resolution transparent PNG master.

The `[SUBJECT]` and `[MEANING]` values for every master are recorded in `manifest.json`.

## Transparency and composition corrections

- 02, 06, and 07 passed genuine-alpha generation; negligible disconnected alpha debris was removed from the accepted workspace copies.
- 03, 04, and 05 received targeted exterior-background extraction after opaque first passes.
- 08, 09, 10, and 12 received targeted exterior-background extraction. Asset 09’s accepted landscape result was proportionally scaled and centered on a transparent square canvas without stretching.
- 11 and 13 rejected repeated fake-checkerboard results and were freshly regenerated with genuine alpha.
- 14–20 passed genuine-alpha generation without compositional edits.
- The app icon was recomposed twice to preserve the complete hero in the required centered 4:3 Messages crop; generated source versions remain preserved outside this project in Codex’s generated-images directory.
- All accepted sticker masters were normalized only at effectively transparent/opaque alpha extremes; RGB artwork was not repainted during that normalization.

## App icon direction

Create an original app-icon master for Bench Bits. Show a chunky translucent red through-hole LED and axial resistor crossing into a loose energetic lightning-bolt silhouette, with two tiny abstract circuit traces and one small spark. Use the same Workbench Pop material, keyline, lighting, and palette language. Center the complete hero composition within the middle 58% so it survives a centered 4:3 crop. Use a full-bleed, fully opaque deep-cobalt-to-ink background with a subtle abstract circuit pattern. No transparency, white sticker border, words, marks, branded parts, Apple UI, Apple emoji styling, rounded app-icon mask, or copied composition. Output a square high-resolution PNG with square corners.

## Human QA gates

- The component silhouette is technically recognizable at thumbnail size.
- There are no accidental letters, numbers, logos, faces, or extra component leads.
- The warm-white border is continuous and the exterior is genuinely transparent.
- Materials, keyline weight, lighting direction, viewing angle, palette, and visual density feel consistent with the set.
- The action or emotional meaning is legible without relying on a caption.
