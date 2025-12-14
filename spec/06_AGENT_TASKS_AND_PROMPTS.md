# Codex agent plan (v1, updated)

This project is implemented via multiple Codex agents. Each agent receives:
- A scoped task goal
- A strict "do not do" list
- The minimal set of context files needed

## Global constraints for ALL agents
- v1 is stateless + ephemeral. Do not implement persistent case repos.
- Do not introduce secrets, env vars, APIs, databases, or web servers.
- Deposits are rendered as bullet lists only (no tables).
- `chains_in_scope` defines deposit chains only.
- Figures may cover non-deposit chains, but every deposit chain must be covered by at least one figure.
- Workdir is deleted after run unless `--keep-workdir`.

## Agent 0: Scaffold
Goal: create the repository skeleton, devenv, justfile, and README.
Context:
- 00_PROJECT_OVERVIEW.md
- 01_WORKDIR_LAYOUT.md
- 06_AGENT_TASKS_AND_PROMPTS.md (this file)
Do:
- Create initial file tree under repo.
- Create `devenv.nix` with Rust + Python + LuaLaTeX + latexmk + just.
- Create `justfile` with validate/canonicalize/render/pdf/build.
Do not:
- Implement business logic.

Prompt (Agent 0):
"Create the repo scaffold for project Caseforge per the workdir layout spec. Add devenv.nix (no services) and a justfile with commands: validate, canonicalize, render, pdf, build. Add a concise README.md describing ephemeral runs and outputs."

## Agent 1: Rust case.yaml + validation
Goal: parse case.yaml into structs and validate hard errors vs warnings.
Context:
- schemas/case_v1.schema.json
- reference/rust_casefile_v1.rs
- 02_CASE_YAML_SPEC.md
- registry/chain_registry_v1.json
Do:
- Implement serde structs + validate() with coverage rule.
- Output machine-readable validation.json.
Do not:
- Parse CSV or render LaTeX.

Prompt (Agent 1):
"Implement CaseFileV1 structs and validation exactly per reference/rust_casefile_v1.rs and schemas/case_v1.schema.json. Enforce: unique chains_in_scope; supported chain_id for deposit chains; each deposit chain covered by >=1 figure.chains_covered. Warn when figures include non-deposit chains."

## Agent 2: Rust chain registry
Goal: implement explorer URL templating.
Context:
- registry/chain_registry_v1.json
- 03_CHAIN_REGISTRY_SPEC.md
Do:
- Provide tx_url() and address_url() functions.
- Unit tests for bitcoin, polygon, monero.
Do not:
- Validate YAML or parse CSV.

Prompt (Agent 2):
"Implement a chain registry module that loads registry/chain_registry_v1.json and provides tx_url(chain_id, tx_hash) and address_url(chain_id, address). Add unit tests for several chains including monero tx-only."

## Agent 3: Rust CSV canonicalization
Goal: parse deposits.csv for each deposit chain and write canonical CSV.
Context:
- 04_CSV_PARSING_SPEC.md
- 02_CASE_YAML_SPEC.md
Do:
- For each chain in chains_in_scope, read artifacts/chains/<chain_id>/deposits.csv.
- Parse UTXO vs Account schema.
- UTXO: parse Crypto Value as '<amount> <symbol>' with strict 2-token rule.
- USD: blank/N/A/- => 0; strip $ , () ; negative => hard error.
- Write build/canonical/deposits/<chain_id>.csv with normalized schema.
Do not:
- Render LaTeX or compile PDF.

Prompt (Agent 3):
"Implement deposits.csv parsing + canonicalization per 04_CSV_PARSING_SPEC.md. Emit canonical CSVs and per-chain row counts into build/manifest.json."

## Agent 4: Rust CLI wizard (ephemeral run)
Goal: interactive wizard that runs end-to-end in a temp workdir and produces outputs in --out.
Context:
- 00_PROJECT_OVERVIEW.md
- 01_WORKDIR_LAYOUT.md
- 02_CASE_YAML_SPEC.md
Do:
- Implement `caseforge wizard --out <dir> [--keep-workdir]`.
- Create temp workdir internally; copy user files into artifacts/ with required naming.
- Generate case.yaml (no comments).
- Run validate, canonicalize, render, pdf (invoke internal functions or subcommands).
- Copy outputs to --out: pdf + attachments.zip.
- Delete workdir unless --keep-workdir.
Do not:
- Implement web UI, persistence, or APIs.

Prompt (Agent 4):
"Implement an interactive CLI wizard that collects required case.yaml fields and files, runs the pipeline in a temp workdir, emits outputs to --out, and deletes workdir unless --keep-workdir."

## Agent 5: Python bullet fragment renderer
Goal: generate LaTeX bullet fragments from canonical CSVs.
Context:
- 05_RENDERING_SPEC.md
- registry/chain_registry_v1.json
Do:
- Read build/canonical/deposits/<chain_id>.csv.
- Generate report/generated/tables/<chain_id>_deposits_bullets.tex.
- Hyperlink tx hash using tx_url_template; hyperlink deposit address if address template exists.
- Render USD only if usd_value > 0.
Do not:
- Compile LaTeX or parse raw deposits.csv.

Prompt (Agent 5):
"Implement Python module to generate LaTeX bullet fragments per chain from canonical CSVs. Use registry JSON to hyperlink tx and addresses."

## Agent 6: LaTeX template wiring
Goal: LuaLaTeX template that matches example style.
Context:
- 05_RENDERING_SPEC.md
- 02_CASE_YAML_SPEC.md
Do:
- Create report/templates/sof_notification_v1/main.tex and preamble.
- Consume case.yaml variables and include generated bullet fragments.
- Render figures in order with caption and optional explanation; support portrait/landscape.
Do not:
- Parse CSV in LaTeX.

Prompt (Agent 6):
"Create LuaLaTeX template sof_notification_v1 that includes bullet fragments and figures with captions and orientation. Keep style close to example."

## Agent 7: End-to-end fixture + just test
Goal: provide example inputs and ensure build works locally.
Context:
- examples/example_case.yaml
Do:
- Add sample deposits.csv files (UTXO + account) and placeholder figures.
- Add just test to run the pipeline.
