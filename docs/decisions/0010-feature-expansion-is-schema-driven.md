# ADR 0010: Feature expansion is schema-driven

- Status: Accepted
- Date: 2026-04-12

## Context

If features expand through custom ad hoc code paths, CaseForge will become harder to extend and harder to validate.

The project needs a better developer experience for adding new feature families such as:
- blockchain analysis
- OSINT
- cyber/infrastructure
- legal/process support

## Decision

Feature expansion should be driven by explicit schemas and manifests rather than custom one-off behavior.

Two contracts are needed:
- an investigator-facing feature config schema
- a feature-author extension schema describing what a feature contributes and which build stages it affects

## Consequences

- adding a feature becomes more declarative
- strict validation becomes possible
- Codex tasks can implement features against stable extension points instead of improvising structure
