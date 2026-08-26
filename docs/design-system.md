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

## Themes

The application supports `System`, `Light`, and `Dark` modes. System is the
default and follows the operating-system `prefers-color-scheme` preference.
An explicit choice is stored in browser `localStorage` under
`lit-bootcamper-theme` and survives Turbo navigation and browser restarts.

Theme values override semantic tokens on the document root. Components must
continue using semantic utilities such as `bg-surface` and `text-ink`; do not
add light/dark palette values directly to templates. The theme selector is
keyboard accessible and the initial layout script applies the resolved theme
before paint to avoid a flash of the wrong palette.

Both palettes use high-contrast ink, muted text, border, and focus values for
WCAG AA normal-text targets. Any new token must be checked in both themes.

## Application shell

The shared layout provides a keyboard-accessible skip link, a desktop sidebar
from the `md` breakpoint, and a fixed mobile bottom navigation below it. The
same six destinations are always shown in the same order: Home, Workshop,
Tasks, Team, Calendar, and Profile. Future tickets add the destination routes;
the shell owns only their consistent presentation and responsive behavior.
