# Chain registry (v1)

v1 defines a blockchain as "supported" if:
- a transaction explorer URL template is available.

Address links are optional per chain.

The registry is implemented in Rust as a static map:
- `chain_id -> { tx_url_template, address_url_template? }`

Templates use placeholder substitution:
- `<tx>` replaced by transaction hash
- `<address>` replaced by address hash
