# ADR 0005: Feature lifecycle is config-driven, not init-only

- Status: Accepted
- Date: 2026-04-12

## Context

Early redesign work treated feature selection as something mostly decided at workspace initialization.

That model is too rigid for a live investigation where:
- new raw exports arrive over time
- new analysis needs emerge during the case
- investigators may want to enable or disable capabilities while the case is active

## Decision

Feature state will be controlled by a workspace config file rather than being fixed forever at `init-workspace`.

The config will describe:
- active features
- per-feature settings
- output profile settings
- future policies affecting feature behavior

## Consequences

- enabling a feature becomes part of normal case evolution
- rebuild behavior must be tied to feature classes and invalidation rules
- future UI work should edit the same config, not create a second source of truth
- workspace initialization should focus on creating the core case workspace, not freezing all future capabilities
