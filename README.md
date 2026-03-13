# ProjForge

ProjForge creates a **self-contained Evidence.dev project per case**.

Each case directory is its own standalone Evidence project.  
That means each case can:

- Run locally (`npm run dev`)
- Be built as static output (`npm run build`)
- Be archived or delivered to a client
- Be hosted independently later

---

# Installation

No installation required yet.

Run commands directly using:

    python tools/ProjForge.py <command> ...

---

# Commands

## Create a New Case

    python tools/ProjForge.py new-case \
      --cases-home /path/to/cases-home \
      --case-id 12343 \
      --title "Avail Holding Ltd"

### Example

    python tools/ProjForge.py new-case \
      --cases-home /Blockchain-Nodes/ProjForge \
      --case-id 12343 \
      --title "Test Case"

This creates:

    /Blockchain-Nodes/ProjForge/12343_<timestamp>/

That directory is now the repo root for that case.

---

# After Case Creation

    cd /Blockchain-Nodes/ProjForge/<case_slug>
    npm install
    npm run dev

Open the URL printed by Evidence.

---

# Data Workflow

## 1) Place Raw Files

Put vendor exports and manual CSV files into:

    data/raw/

Do not modify raw files in place.  
If transformations are required, save a new file version.

---

## 2) Build the Case Database

    duckdb data/case.duckdb < data/load.sql

This runs the per-case loader snapshot.

---

## 3) Refresh Evidence Sources

    npm run sources

Reload the browser.

---

# Build Static Output (Optional)

    npm run build

This creates a `build/` directory that can be hosted on:

- A VPS
- A static server
- An internal investigation server
- Packaged for client delivery

---

# Template Behavior

When creating a case:

1. If a local template exists at:

       <cases-home>/evidence-templates/template/

   It will be copied.

2. Otherwise ProjForge runs:

       git clone --depth 1 https://github.com/evidence-dev/template

---

# Case Structure

Each case directory contains:

    pages/
      01-introduction.md
      02-off-chain-analysis.md
      03-on-chain-analysis.md
      04-dormant-addresses.md
      05-conclusion-and-recommendations.md
      06-appendix.md

    sources/
      case/
        connection.yaml

    data/
      raw/
      case.duckdb
      load.sql

    README.md

---

# Design Philosophy

- One case = one Evidence project
- Reproducible: data/load.sql is copied per case
- Portable: copy the entire folder and it runs
- Evolvable: loader logic can change without breaking historical cases

---

# Current Scope (v1)

Included:
- Case scaffolding
- Evidence template bootstrap
- Page structure generation
- DuckDB source creation
- Per-case loader snapshot

Not yet implemented:
- CSV intake automation
- Vendor detection (Qlue / TRM / manual)
- Database build automation
- Backend API endpoints
- Multi-case hosting architecture
