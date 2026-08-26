# Design System Foundation

E2-01 defines the first visual contract for Lit Bootcamper. The CSS token layer
is the initial source of truth; a matching Figma library can be created from
these names without changing application code.

## Principles

- Use semantic tokens (`surface`, `ink`, `copper`, `teal`) in templates.
- Do not use raw palette values in components.
- Prefer Tailwind utilities; add custom CSS only for shared behavior or base styles.
- Keep motion decorative and respect `prefers-reduced-motion`.

## Token groups

| Group | Semantic names | Purpose |
| --- | --- | --- |
| Color | `surface`, `surface-raised`, `ink`, `ink-muted`, `copper`, `teal`, `border`, `focus` | Warm steampunk surfaces, readable text, accents, and focus state |
| Space | `page`, `section`, `card`, `control` | Page gutters, section rhythm, card padding, and control gaps |
| Type | `body`, `display`, `title`, `caption` | Body and display typography hierarchy |
| Shape | `card`, `control`, `pill` | Containers, controls, and status labels |
| Elevation | `card`, `lifted` | Resting and emphasized surfaces |
| Motion | `fast`, `standard`, `ease` | Consistent transitions; reduced to zero when requested |

Example: `class="rounded-card bg-surface-raised p-card shadow-card text-ink"`.

The light palette is intentionally established first. Theme-specific token
values belong to E2-02; components should not need to change when they arrive.
