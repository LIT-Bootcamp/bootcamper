# Workshop Map Language

E2-05 defines the first visual and semantic contract for the workshop journey.
The preview at `/design/workshop-map` is intentionally static. It is a design
prototype, not an enrollment or progress implementation.

## Station language

Stations form one ordered path. Each station has a title, a short description,
one state label, and a connector to the next station. The path can later be
backed by ordered course modules without changing its visual vocabulary.

States are explicit:

- **Completed** — a check marker and teal treatment.
- **Current** — an arrow marker and copper emphasis.
- **Locked** — a muted marker and a locked label.

Color is supportive, never the only state signal. The label and marker must
remain understandable in grayscale and with color-vision differences.

Team accents identify a team’s trail or ownership: copper and teal are the
initial examples. They must not replace state labels or imply competition.

## Usability check

Run the preview with three students or colleagues, one at a time, without
explaining the map first. Ask:

1. “Where would you go next?”
2. “Which station is locked, current, and completed?”
3. “What do the two team colors mean?”

Record whether each answer is immediate, prompted, or incorrect, plus one
verbatim confusion per participant. Findings and any resulting adjustments
remain pending until participants are available; no results are invented in
this repository.

## Future boundary

E6-10 will replace illustrative stations with enrolled course modules and
real progress. E2-06 will verify keyboard navigation, reduced motion, and
complete text equivalents.
