---
name: blending-textured-backgrounds
description: Use when two stacked or adjacent full-bleed sections share the same textured/image/gradient background and a visible hard seam appears where they meet (cover-crops don't line up), or when you want one section's background to dissolve into the next instead of butting against it.
---

# Blending Textured Backgrounds

## Overview

Two adjacent full-bleed sections that each paint the **same** texture with
`background-size: cover` will still show a **hard seam** where they meet: each
section box has a different aspect ratio, so `cover` crops the image differently
in each. The textures don't register, and the join reads as a line.

**Core principle:** Don't make two cover-crops meet. Instead, paint the lower
section's background on an absolutely-positioned layer that **overlaps upward**
into the section above and is **alpha-masked to fade in**, so its texture
crossfades over the section above rather than meeting it at an edge.

## When to Use

- Adjacent sections share a textured/photographic/gradient background and a seam
  is visible at the boundary.
- You want a background to dissolve into the next section.

**When NOT to use:**
- Backgrounds are flat solid colors — just set the same color, there's no seam.
- You *want* a hard divider between sections.
- A single background behind both sections is feasible — simpler to put one
  background on a shared parent wrapper.

## Core Pattern

```css
/* BEFORE — two cover-crops butt together → hard seam */
.section-a { background: url(texture.png) center / cover; }
.section-b { background: url(texture.png) center / cover; }
```

```css
/* AFTER — section B's background crossfades over section A */
.section-b        { position: relative; }   /* anchor for ::before */
.section-b__inner { position: relative; z-index: 2; } /* content above the layer */

.section-b::before {
  content: "";
  position: absolute;
  inset: -64px 0 0 0;        /* top: -64px extends UP into section A */
  z-index: 0;                /* behind the content */
  pointer-events: none;      /* don't eat clicks in section A */
  background: url(texture.png) top center / cover;
  /* fade transparent -> opaque across the overlap, finishing at B's real top */
  -webkit-mask-image: linear-gradient(to bottom, transparent 0, #000 64px);
          mask-image: linear-gradient(to bottom, transparent 0, #000 64px);
}
```

The overlap distance (`top: -64px`) and the mask's fade distance (`64px`) are
the **same value** so the fade completes exactly at section B's true top edge.

## Quick Reference

| Concern | Do this |
| :--- | :--- |
| Anchor the layer | `position: relative` on the section |
| Keep content visible | content wrapper `position: relative; z-index: 2` (above the layer's `z-index: 0`) |
| Overlap upward | `top: -Npx` (negative) on the `::before` |
| Crossfade | `mask-image: linear-gradient(to bottom, transparent 0, #000 Npx)` |
| Safari support | include `-webkit-mask-image` too |
| Don't block clicks | `pointer-events: none` on the layer |
| Make textures register | `::before` layer uses same `background-position`/sizing as section above (`top center / cover`) |

## Common Mistakes

- **No `position: relative` on the section** → the `::before` anchors to the
  viewport or a distant ancestor, not the section.
- **Content hidden behind the layer** → give the content wrapper a higher
  `z-index` than the layer.
- **`mask-image` without `-webkit-mask-image`** → broken fade in Safari.
- **Overlap distance ≠ fade distance** → fade finishes too early/late, leaving a
  faint residual line.
- **Mask on the section itself instead of a layer** → masks the content too, not
  just the background.

## Notes

- Works for any paint, not just texture PNGs: photos and gradients have the same
  cover-crop mismatch and blend the same way.
- For dynamic backgrounds (CMS/theme settings), keep the static positioning in a
  stylesheet and inject only the fill (`background-color`/`background-image`)
  inline, so the blend mechanics stay in one place.
- Increase the overlap/fade distance for a softer, longer crossfade; decrease it
  for a tighter blend.
