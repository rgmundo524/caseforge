# First Vertical Slice

## Goal

Prove that the redesign works without attempting the full system.

## The slice

The first vertical slice should do exactly this:

1. create a persistent case workspace
2. scaffold the core top-level directories
   - `Sections/`
   - `Sources/`
   - `WEB/`
   - `PDF/`
3. generate a small starter set of section markdown files
4. register one sample evidence file into `Sources/`
5. build the case DuckDB in `Sources/`
6. generate one Evidence-based web output in `WEB/`
7. expose the flow through a thin FastAPI backend

## Minimum authored sections for the slice

Suggested starter set:
- `case-background.md`
- `investigative-findings.md`
- `conclusion.md`

Each section should:
- be a separate markdown file
- have minimal frontmatter
- be placed into the web output by a simple deterministic rule

## Out of scope

For the first slice, do not solve:
- PDF rendering
- full metadata schema
- multi-output selection
- complete Obsidian integration strategy
- cross-case shared knowledge
- full user management
- elegant front-end UX

## Success criteria

The slice is successful if:
- a case workspace can be created repeatably
- investigators can edit source sections
- data ingestion/build still works in the new workspace model
- one web output can compose authored content plus structured case data
- the branch demonstrates the redesign is operationally viable
