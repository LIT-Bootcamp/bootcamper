# Cyberpunk Platform Design Brief

## Product identity

The platform is generic **Bootcamper**. Do not use “LIT” in platform navigation,
layout branding, metadata, or shared UI copy. Organization and course ownership
may be represented as configurable course data later.

## Visual direction

- Near-black blue-violet surfaces with layered depth.
- Neon cyan as the primary action signal.
- Electric magenta, acid lime, and warning amber as secondary accents.
- Glowing borders, softly rounded panels, and restrained bloom effects.
- Friendly geometric display type paired with monospace utility text only where it
  communicates telemetry or system state.
- Large, calm content blocks with clear hierarchy, gradient emphasis, and generous
  breathing room; cyberpunk details should sharpen the composition rather than
  make it noisy.
- Grid overlays, signal traces, terminal fragments, and status telemetry.
- Asymmetrical compositions with deliberate technical density.
- Reference the visual rhythm of a polished learning dashboard: pill navigation,
  centered hero moments, compact stat strips, and modular content cards. Do not
  copy any reference artwork, wording, branding, or assets.
- Glitch/noise details used as accents, never as decoration over content.

## Interaction mood

The interface should feel like a friendly learner’s operations console:
playful, energetic, useful, and slightly mysterious. Progress should look like
activating systems, unlocking nodes, and routing through a network—not filling
out a corporate dashboard.

## Accessibility boundary

Neon accents must not be the only state signal. Every state needs text, icon,
or structural distinction. Focus visibility, reduced motion, readable contrast,
and mobile usability remain mandatory.

## Scope reset

Rework the existing visual tokens and shell toward this direction. Preserve the
Rails/Tailwind architecture and functional behavior. Fix the mobile overflow as
part of the shell redesign.
