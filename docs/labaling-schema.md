# CaseForge Labeling and Transaction Schema

## Purpose

CaseForge uses a lightweight investigator-facing labeling schema to enrich raw transfer data with attribution, traced-value context, theft markers, service relationships, and cross-chain hints.

The schema is intentionally designed so that **all parts of a label are optional unless a specific workflow requires them**. In practice, that means label sparsity is normal. A missing traced value, missing dormant value, missing asset, or missing counterparty does **not** automatically indicate bad ingestion or a parser defect. Often it simply means the investigator chose not to provide that level of detail.

This is important to how CaseForge should be interpreted:

- raw transfer data remains the primary factual input
- labels add investigative context on top of that raw transfer data
- defaults and inference rules exist to reduce labeling effort
- missing optional label parts should not be treated as data-quality failures by themselves

The keywords in the schema are also intended to support SQL-driven filtering, downstream views, and Evidence pages.

---

## Canonical Label Shape

CaseForge uses the same general mini-language for **transfer labels** and **address labels**:

```text
[transfer action / address type] Counterparty name (Value Asset), [transfer action / address type] Counterparty name (Value Asset)
```

At a high level:

- `[]` contains either **transfer actions** or **address types**
- free text between `[]` and `()` is the **counterparty / operator / investigator note**
- `()` contains a **value/asset pair** when supplied
- top-level comma-separated segments represent **multiple label entries**

For transfer labels, the comma behavior is especially important for **Qlue UTXO exports**. A single raw transaction-level transfer label may use commas to carry distinct labels for different transfer legs in the same transaction. In that situation, the comma is not just punctuation; it is the delimiter between separate label entries that later need leg-level assignment.

The meaning of the label depends on where it appears:

- in a **transfer label**, parentheses represent the **traced value** and optional traced asset
- in an **address label**, parentheses represent the **dormant value** and optional dormant asset

---

## Design Principles

### 1. Optionality is intentional

The schema is designed to work with partial investigator input. A label does **not** need to contain every component.

Examples of valid sparse labels include:

- `[D] OKX`
- `[Internal]`
- `Change`
- `(0.02458389 BTC)`
- `0.02458389`
- `[DA] Coinbase`

### 2. Defaulting is part of the model

CaseForge applies limited defaulting so investigators only have to label the exceptions that matter.

The most important example is traced value on transfer labels:

- when a transfer label applies to a row but **does not provide a traced value**, the system may default the traced/stolen amount to the **full applicable transfer amount**
- this is an intentional inference, not a claim that the label explicitly stated the full amount
- the rationale is that if the transaction was included in the investigative dataset, it is often acceptable to assume the included transfer is fully relevant unless the investigator narrows it with a smaller traced value

This lets investigators focus their labeling effort on cases where the traced amount is **less than** the row amount.

### 3. Missing detail is not the same as bad data

The absence of:

- a traced value in a transfer label, or
- a dormant value in an address label

means only that the detail was **not provided**. It should not be treated as proof that the parser missed data.

### 4. Parsed columns exist to make the labels queryable

The raw labels should always remain visible, but the project also parses them into structured columns so SQL can filter on:

- action/type keywords
- counterparties
- traced value and asset
- dormant value and asset
- theft and cross-chain indicators
- assignment status for UTXO multi-leg rows

---

## Transfer Labels

A **transfer label** describes what the transfer is doing in the investigative context.

Examples:

```text
[D] OKX (0.02458389 BTC)
[Theft/W] (0.02458728 BTC)
[CC:2:OUT/D] (3,137.188604 USDT)
Change
0.02458389
```

### Transfer action keywords

Keywords are **case-insensitive**.

| Keyword | Meaning |
|---|---|
| `[D]` | Deposit transfer to a VASP (Virtual Asset Service Provider) |
| `[W]` | Withdrawal transfer from a VASP |
| `[THEFT]` | Theft transfer from a victim to a theft address |
| `[SWAP]` | Non-custodial DeFi asset swap transfer |
| `[CC:#:IN]` | Input transfer to a cross-chain transaction, where `#` is the match identifier |
| `[CC:#:OUT]` | Output transfer from a cross-chain transaction, where `#` is the match identifier |
| `[Internal]` | Transfer internal to a VASP, often used as an attribution artifact |

### Multiple transfer actions in one label

A single transfer can carry more than one action, so action keywords may be combined inside the brackets using `/` or `\`.

Examples:

```text
[Theft/W]
[CC:2:OUT/D]
```

Interpretation:

- `[Theft/W]` means the labeled transfer is both theft-related and a withdrawal
- `[CC:2:OUT/D]` means the labeled transfer is the output side of cross-chain pair `2` and is also treated as a deposit

### Counterparty in transfer labels

Everything between the bracketed action block and the parenthetical value block is treated as the **counterparty**.

For transfer labels, counterparty can be:

- a VASP name such as `OKX`, `Coinbase`, `HTX`, `Gate.io`
- an open-ended investigator label such as `Change`
- omitted entirely

Examples:

```text
[D] OKX (0.02458389 BTC)
[D] CashApp (0.00288707 BTC), Change
[Internal] Coinbase
```

### Parenthetical value in transfer labels

In transfer labels, `()` contains the **traced value** and optional **traced asset**.

Examples:

```text
[D] OKX (0.02458389 BTC)
[Theft/W] (2,979.132819 USDC)
```

Interpretation:

- `0.02458389` or `2,979.132819` is the traced amount
- `BTC` or `USDC` is the traced asset

#### Transfer-label defaults

If a value is present but the asset is omitted:

- the traced asset defaults to the row's transaction asset

Special case:

- if the transfer label consists only of a numeric value (with punctuation allowed), it is treated as the traced value
- the traced asset then defaults to the row asset

Example:

```text
0.02458389
```

is interpreted as:

- traced value: `0.02458389`
- traced asset: the row asset

#### Important formatting rule

Asset recognition requires at least **one whitespace** between value and asset.

Example:

```text
(0.02458389 BTC)
```

is parseable, while a value/asset run together without whitespace is not guaranteed to parse correctly.

#### When the traced value is omitted

If the transfer label does not include a traced value, that omission means the investigator did not specify it.

CaseForge may still infer the effective traced/stolen amount from the transfer amount when the label applies to that leg. That inference is a convenience behavior and should be understood separately from the literal label text.

---

## Address Labels

An **address label** describes what kind of address is involved and, optionally, who operates it and what dormant value remains there.

Examples:

```text
[TA] TrustFlow
[DA] OKX
[CC] Thorchain
[HOT] Binance
[DA] Unidentified
```

### Address type keywords

Keywords are **case-insensitive**.

| Keyword | Meaning |
|---|---|
| `[VA]` | Victim address |
| `[VE]` | Victim exchange |
| `[TA]` | Theft address, typically the initial recipient of stolen funds |
| `[DA]` | Deposit address, often associated with a specific VASP |
| `[DC]` | Deposit contract, similar to a deposit address but contract-based |
| `[HOT]` | VASP hot wallet / operational address, often involved in internal VASP activity |
| `[CC]` | Address associated with a cross-chain transfer included in the data |

### Counterparty in address labels

Everything between the bracketed type block and the parenthetical value block is treated as the **operator / counterparty** of the address.

For address labels, this usually means the service that operates the address.

Examples:

```text
[DA] OKX
[DA] Gate.io
[CC] Thorchain
[TA] TrustFlow
```

### Parenthetical value in address labels

In address labels, `()` contains the **dormant value** and optional **dormant asset**.

Examples:

```text
[DA] Example Service (12.5 ETH)
[TA] Example Theft Address (0.4 BTC)
```

Interpretation:

- `12.5` or `0.4` is the dormant value
- `ETH` or `BTC` is the dormant asset

#### Address-label defaults

Conceptually, if a dormant value is present and no dormant asset is supplied, the dormant asset should default to the **native asset of the blockchain** for that row.

However, that native-asset lookup has **not been implemented yet**.

Because of that, the current practical rule is:

- when an address label includes a dormant value, the asset should also be provided

#### When the dormant value is omitted

If the address label does not include a dormant value, that means the investigator did not provide dormant-amount detail. It should not be interpreted as a parser failure.

---

## Multi-Entry Labels

Labels may contain multiple comma-separated entries.

For **Qlue UTXO transfer labels**, this is an intentional part of the schema. A single raw transfer-label string can contain distinct leg-specific entries that must later be split and mapped to the correct leg.

Example:

```text
[D] CashApp (0.00288707 BTC), Change
```

This represents two distinct entries:

1. `[D] CashApp (0.00288707 BTC)`
2. `Change`

Another example:

```text
[D] Coinbase (0.00197057 BTC), change (0.00376989 BTC)
```

This represents two explicit legs:

1. a deposit to Coinbase
2. a change output carrying `0.00376989 BTC`

For UTXO transactions, multi-entry parsing matters because a single raw transaction label may need to be split into separate entries and then assigned to the correct transfer leg.

### Important delimiter rule

Entry splitting should occur on **top-level entry commas**, not blindly on every comma character.

That distinction matters because labels may also contain commas as numeric thousands separators inside parentheses, for example:

```text
[CC:2:OUT/D] (3,137.188604 USDT)
[Theft/W] (2,979.132819 USDC)
```

Those numeric commas are part of the value and should **not** create extra label entries.

---

## Parsing and Normalization Rules

CaseForge should apply the following parsing assumptions consistently.

### Comma-separated transfer-label entries

Transfer labels may contain multiple entries separated by **top-level commas**.

This exists primarily to support Qlue UTXO exports where one raw transaction-level label carries multiple leg-specific labels.

Parsing should therefore:

- split on entry-separator commas at the top label level
- avoid splitting commas that are part of numeric formatting inside parentheses
- preserve entry order so later assignment logic can audit what was seen in the raw label

After splitting, each entry should be treated as its own parseable label fragment with its own actions, counterparty, value, asset, and assignment outcome.

### Case-insensitive keyword matching

Keyword matching is case-insensitive.

Examples that should be treated the same at the keyword level:

```text
[D]
[d]
[Theft]
[THEFT]
[Internal]
[internal]
```

### Bracket normalization

Minor bracket normalization is acceptable where raw export formatting is inconsistent, as long as the semantic content is preserved.

### Slash-separated actions

Within `[]`, `/` and `\` separate multiple action keywords inside a single entry.

### Parenthetical parsing

`()` is used for structured value parsing, but its semantics depend on label type:

- transfer label -> traced value / traced asset
- address label -> dormant value / dormant asset

### Free-text counterparty parsing

Everything between the closing `]` and opening `(` is treated as counterparty text after trimming surrounding whitespace.

This counterparty may be:

- a service name
- a free-text routing note such as `Change`
- blank / absent

### Numeric-only label edge case

A transfer label that is just a numeric token should be interpreted as traced value with inferred asset.

Example:

```text
0.02458389
```

---

## Inference Rules

The schema intentionally supports minimum-viable labeling.

### Traced value fallback

When a transfer label applies to a leg but does not explicitly provide a traced value, CaseForge may infer the effective traced amount from the full row amount.

This behavior exists because:

- the transaction is already in the investigative dataset
- many rows are fully relevant unless the investigator narrows the amount
- investigators save time by only specifying a value when it is less than the full row amount

### Asset inheritance

If a transfer label provides a value but not an asset:

- the asset defaults to the row asset

### Address dormant asset default

If an address label provides a dormant value but not an asset:

- the conceptual default is the chain's native asset
- this is not yet implemented
- for now, dormant-value address labels should include the asset explicitly

### Leg assignment for UTXO transactions

UTXO transaction labels may be attached at the transaction level in source exports, not at the leg level. CaseForge therefore needs parsing and assignment layers that:

- split multi-entry labels
- evaluate candidate legs
- resolve which leg a label entry applies to
- allocate traced/stolen amount to the chosen leg

This behavior is structural to the project and should not be treated as optional plumbing.

For comma-separated multi-entry UTXO labels, **counterparty matching against the relevant address label** is an especially strong signal. In practice that means an entry like `CashApp` should strongly prefer an output leg whose receiving label resolves to `CashApp`, and a `change` entry should strongly prefer a change-labeled output.

That said, counterparty matching should be treated as a **priority rule, not the only rule**, because some valid entries have:

- no counterparty
- no value
- no usable destination label
- cross-chain side semantics that matter more than named counterparty matching

A sensible priority order is:

1. explicit cross-chain side match, when present
2. theft-side match, when present
3. normalized counterparty-to-address-label counterparty match
4. value-fit / capacity-fit checks
5. single-leg fallback only when the remaining candidate set is unambiguous

If a multi-entry label is still ambiguous after those checks, it is usually better to leave it unresolved than to force an incorrect assignment.

---

## How the Labeling Schema Maps to the Transaction Schema

CaseForge's transaction model is ultimately meant to make raw transfer data and investigator labels queryable together.

### Canonical grain

The canonical grain is **one row per transfer leg**.

That means:

- repeated `tx_hash` values are normal
- account-model transactions may produce multiple rows
- UTXO transactions commonly produce multiple rows
- labels often have to be interpreted at the leg level, not just the transaction-hash level

### Raw label-bearing columns

At minimum, the transaction surfaces should preserve the raw investigator-provided context in columns such as:

- `transfer_label`
- `from_label`
- `to_label`
- `address_label`

### Parsed transfer-label columns

The parsed transaction surfaces should expose structured transfer-label fields such as:

- `tx_label_entry_raw`
- `tx_label_scope`
- `tx_label_actions`
- `tx_label_counterparty`
- `tx_label_value`
- `tx_label_asset`
- `tx_label_status`
- `tx_label_assignment_status`
- `tx_label_leg_applies`
- `tx_label_leg_match_reason`
- `tx_label_applicable_leg_count`

These are what make the labels filterable and auditable.

### Parsed address-label columns

The parsed transaction surfaces should also expose structured address-label fields such as:

- `from_types`
- `from_counterparty`
- `from_dormant_value`
- `from_dormant_asset`
- `from_label_status`
- `to_types`
- `to_counterparty`
- `to_dormant_value`
- `to_dormant_asset`
- `to_label_status`

These help distinguish address classification from transfer interpretation.

### Derived investigative fields

The transaction schema should derive or carry forward fields that support filtering and debugging, including:

- `stolen_amount_value`
- `stolen_amount_usd_value`
- `theft_id`
- `tx_is_theft`
- `tx_is_cross_chain`
- `tx_cc_id`
- `tx_cc_direction`
- `cc_match_side`
- `cc_match_eligible`

---

## Helper Views for UTXO Label Resolution

Because raw UTXO exports do not reliably attach labels per leg, CaseForge uses helper views to parse and resolve label ownership and assignment.

These helper views include:

- `v_tx_label_entries`
- `v_tx_label_entry_candidates`
- `v_tx_label_entry_resolution`
- `v_tx_label_entry_assignments`
- `v_tx_label_owner_summary`

At a high level:

- `v_tx_label_entries` splits raw labels into individual entries
- `v_tx_label_entry_candidates` evaluates which transfer legs each entry could match
- `v_tx_label_entry_resolution` records whether each entry was resolved cleanly
- `v_tx_label_entry_assignments` records the chosen leg assignment and allocated amount
- `v_tx_label_owner_summary` summarizes entry counts, unresolved cases, and malformed cases by label owner

These views are especially important for:

- multi-output UTXO deposits
- change outputs
- theft / withdrawal labels that apply only to one side of the transaction
- cross-chain input/output annotations on UTXO legs

---

## Observed Behavior in the Current Sample

The attached sample exports indicate that CaseForge already has at least partial implemented support for comma-separated UTXO transfer-label resolution.

Observed examples in the sample include:

- `[D] CashApp (0.00288707 BTC), Change`
- `[D] Coinbase (0.00197057 BTC), change (0.00376989 BTC)`

In both examples, the helper-view layer splits the raw label into separate entries and assigns those entries to distinct output legs. The observed assignment behavior appears to rely on normalized output-counterparty matching, which is consistent with the intended model.

That is encouraging because it means the current codebase is not ignoring this schema feature. The better framing is:

- support for comma-separated UTXO entries appears to exist
- this behavior should be documented explicitly
- the matching rules may still deserve hardening and more explicit tests

## Label Sparsity vs. Data-Quality Problems

When validating CaseForge output, it is important to separate **intentional sparsity** from **actual defects**.

### Usually not a defect

The following conditions are often valid and should not be flagged automatically:

- transfer label with no traced value
- address label with no dormant value
- transfer label with no counterparty
- address label with no counterparty
- numeric-only transfer label
- multi-action transfer label
- missing asset in a transfer label value that correctly inherits from the row asset

### Likely worth investigating

The following are better indicators of real ingestion or parsing issues:

- explicit label content is lost or changed materially
- a clearly parseable value/asset pair fails to parse
- action keywords are not recognized case-insensitively
- multi-entry labels are not split correctly
- a label entry is assigned to the wrong UTXO leg when the correct leg is obvious
- asset inheritance behaves incorrectly
- cross-chain ID or direction is parsed incorrectly
- structured parsed columns contradict the raw label text
- normalized/raw surfaces disagree before any intended interpretation layer

---

## Debugging Ladder

When investigating a suspected data problem, the useful ladder is:

1. `normalized_combined_transactions`
2. `v_normalized_transactions`
3. `v_transfer_base`
4. `v_transfers`
5. `transactions`

Use this ladder to determine whether the problem first appears in:

- raw ingest / normalization
- address-label parsing
- transfer-label parsing
- UTXO leg assignment
- final derived transaction fields

### Practical guidance

- if the raw source fields are already wrong in normalized layers, the issue is in ingest/normalization
- if raw labels are preserved but parsed fields are wrong, the issue is in label parsing
- if parsed entries are correct but applied to the wrong leg, the issue is in assignment logic
- if explicit label text is absent but the system falls back to full amount, that may be intentional default behavior rather than a defect

---

## Worked Examples

### Example 1: Deposit with explicit traced value

```text
[D] OKX (0.02458389 BTC)
```

Interpretation:

- action: deposit
- counterparty: OKX
- traced value: `0.02458389`
- traced asset: `BTC`

### Example 2: Theft plus withdrawal

```text
[Theft/W] (0.02458728 BTC)
```

Interpretation:

- actions: theft + withdrawal
- no counterparty provided
- traced value: `0.02458728`
- traced asset: `BTC`

### Example 3: Numeric-only traced value

```text
0.02458389
```

Interpretation:

- traced value: `0.02458389`
- traced asset: inherit from row asset
- no explicit action
- no explicit counterparty

### Example 4: Multi-entry UTXO output label

```text
[D] CashApp (0.00288707 BTC), Change
```

Interpretation:

- entry 1: deposit to CashApp for `0.00288707 BTC`
- entry 2: change output with no explicit amount unless separately provided
- assignment logic must decide which output leg receives each entry
- an output leg labeled `[DA] CashApp` should be a strong match for the `CashApp` entry
- an output leg labeled `change` / `Change` should be a strong match for the `Change` entry

### Example 5: Cross-chain output that is also a deposit

```text
[CC:2:OUT/D] (3,137.188604 USDT)
```

Interpretation:

- cross-chain pair id: `2`
- direction: output
- additional action: deposit
- traced value: `3137.188604`
- traced asset: `USDT`

### Example 6: Address classification

```text
[DA] OKX
```

Interpretation:

- address type: deposit address
- counterparty/operator: OKX
- no dormant amount provided

---

## Recommended Documentation Positioning

This schema is important enough that it should not live only in code comments or scattered SQL logic. A good documentation split would be:

- `docs/labeling-schema.md` for investigator-facing label semantics
- `docs/transaction-schema.md` for parsed columns, helper views, and debugging flow
- brief links from the main `README.md`

If only one document is added initially, this file can serve as the first draft for that document.

---

## Summary

CaseForge should treat labels as **investigator-supplied enrichment with optional detail**, not as rigid mandatory metadata.

The correct mental model is:

- labels may be sparse
- sparse labels are often intentional
- defaults and inference are part of the product design
- parsed columns exist to make the labels queryable
- helper views exist because UTXO labels are not inherently leg-level in raw exports
- debugging should focus on contradictions, parsing failures, and wrong assignments rather than simply missing optional label parts
