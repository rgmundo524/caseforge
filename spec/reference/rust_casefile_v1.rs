use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CaseFileV1 {
    pub case: CaseMeta,
    pub recipient: Recipient,
    pub investigator: Investigator,
    pub templates: Templates,

    pub stolen_assets: AssetSection,
    pub deposited_assets: DepositedAssetSection,

    // Deposit chains only
    pub chains_in_scope: Vec<ChainScope>,

    // Figures may include additional chains, but every deposit chain must be covered by at least one figure
    pub figures: Vec<FigureSpec>,

    pub law_enforcement: LawEnforcement,
    pub closing: Closing,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CaseMeta {
    pub case_number: String,
    pub internal_case_id: Option<String>,
    pub report_type: String,
    pub report_date: String, // validate YYYY-MM-DD
    pub case_matter: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Recipient {
    pub vasp_name: String,
    pub addressee_group: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Investigator {
    pub name: String,
    pub title: String,
    pub organization: String,
    pub email: String,
    pub phone: Option<String>,
    pub telegram: Option<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Templates {
    pub letter_template_id: String,
    pub language: Language,
}

#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum Language {
    En,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct AssetSection {
    pub assets: Vec<AssetEntry>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct DepositedAssetSection {
    pub assets: Vec<AssetEntry>,
    pub total_usd_estimate: Option<f64>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct AssetEntry {
    pub name: String,
    pub symbol: String,
    pub chain_id: String,
    pub amount: f64,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ChainScope {
    pub chain_id: String,
    pub accounting_model: AccountingModel,
}

#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum AccountingModel {
    Utxo,
    Account,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct FigureSpec {
    pub figure_id: String,
    pub file_type: FigureFileType,
    pub orientation: FigureOrientation,
    pub caption: String,
    pub explanation: Option<String>,
    pub chains_covered: Vec<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum FigureFileType {
    Png,
    Svg,
    Pdf,
}

#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum FigureOrientation {
    Portrait,
    Landscape,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct LawEnforcement {
    pub reported: bool,
    pub agency: Option<String>,
    pub report_reference: Option<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Closing {
    pub signatory_name: String,
    pub signatory_title: String,
    pub signatory_organization: String,
}

#[derive(Debug, Clone)]
pub struct ExplorerTemplates {
    pub tx_url_template: String,
    pub address_url_template: Option<String>,
}

pub trait ChainRegistry {
    fn get(&self, chain_id: &str) -> Option<&ExplorerTemplates>;
}

#[derive(Debug, Clone)]
pub struct ValidationWarning {
    pub code: &'static str,
    pub message: String,
}

#[derive(Debug, Clone)]
pub struct ValidationError {
    pub code: &'static str,
    pub message: String,
}

impl CaseFileV1 {
    pub fn validate(&self, registry: &dyn ChainRegistry) -> Result<Vec<ValidationWarning>, Vec<ValidationError>> {
        let mut errors: Vec<ValidationError> = Vec::new();
        let mut warnings: Vec<ValidationWarning> = Vec::new();

        let mut err = |code: &'static str, message: String| { errors.push(ValidationError { code, message }); };
        let mut warn = |code: &'static str, message: String| { warnings.push(ValidationWarning { code, message }); };

        // Required strings
        check_nonempty(&self.case.case_number, "case.case_number", &mut err);
        check_nonempty(&self.case.report_type, "case.report_type", &mut err);
        check_nonempty(&self.case.report_date, "case.report_date", &mut err);
        check_nonempty(&self.case.case_matter, "case.case_matter", &mut err);

        check_nonempty(&self.recipient.vasp_name, "recipient.vasp_name", &mut err);
        check_nonempty(&self.recipient.addressee_group, "recipient.addressee_group", &mut err);

        check_nonempty(&self.investigator.name, "investigator.name", &mut err);
        check_nonempty(&self.investigator.organization, "investigator.organization", &mut err);
        check_nonempty(&self.investigator.email, "investigator.email", &mut err);

        check_nonempty(&self.closing.signatory_name, "closing.signatory_name", &mut err);
        check_nonempty(&self.closing.signatory_title, "closing.signatory_title", &mut err);
        check_nonempty(&self.closing.signatory_organization, "closing.signatory_organization", &mut err);

        if !is_yyyy_mm_dd(&self.case.report_date) {
            err("INVALID_DATE", "case.report_date must match YYYY-MM-DD".to_string());
        }

        // Template constraints
        if self.templates.letter_template_id != "sof_notification_v1" {
            err("UNSUPPORTED_TEMPLATE", format!("templates.letter_template_id must be sof_notification_v1, got {}", self.templates.letter_template_id));
        }
        if self.templates.language != Language::En {
            err("UNSUPPORTED_LANGUAGE", "templates.language must be en in v1".to_string());
        }

        if self.stolen_assets.assets.is_empty() {
            err("MISSING_STOLEN_ASSETS", "stolen_assets.assets must have at least one entry".to_string());
        }
        if self.deposited_assets.assets.is_empty() {
            err("MISSING_DEPOSITED_ASSETS", "deposited_assets.assets must have at least one entry".to_string());
        }
        if self.chains_in_scope.is_empty() {
            err("MISSING_CHAINS_IN_SCOPE", "chains_in_scope must have at least one entry".to_string());
        }
        if self.figures.is_empty() {
            err("MISSING_FIGURES", "figures must have at least one entry".to_string());
        }

        // Unique chains_in_scope + supported chains
        let mut scope_chain_ids: HashSet<String> = HashSet::new();
        for scope in &self.chains_in_scope {
            if !scope_chain_ids.insert(scope.chain_id.clone()) {
                err("DUPLICATE_CHAIN", format!("Duplicate chain_id in chains_in_scope: {}", scope.chain_id));
            }
            if registry.get(&scope.chain_id).is_none() {
                err("UNSUPPORTED_CHAIN", format!("Unsupported chain_id in chains_in_scope: {}", scope.chain_id));
            }
        }

        // Validate figures; warn if figure includes non-deposit chains
        let mut figure_ids = HashSet::new();
        let mut covered_by_figures: HashSet<String> = HashSet::new();
        for fig in &self.figures {
            if !figure_ids.insert(fig.figure_id.clone()) {
                err("DUPLICATE_FIGURE_ID", format!("Duplicate figure_id: {}", fig.figure_id));
            }
            if fig.caption.trim().is_empty() {
                err("EMPTY_CAPTION", format!("Figure {} caption must be non-empty", fig.figure_id));
            }
            if fig.chains_covered.is_empty() {
                err("FIGURE_NO_CHAINS", format!("Figure {} must cover at least one chain_id", fig.figure_id));
            }

            for chain_id in &fig.chains_covered {
                // chain_id must be supported to hyperlink tx hashes if used later in rendering
                if registry.get(chain_id).is_none() {
                    warn("FIGURE_UNSUPPORTED_CHAIN", format!("Figure {} references chain_id without explorer templates: {}", fig.figure_id, chain_id));
                }
                if scope_chain_ids.contains(chain_id) {
                    covered_by_figures.insert(chain_id.clone());
                } else {
                    warn("FIGURE_NON_DEPOSIT_CHAIN", format!("Figure {} includes non-deposit chain_id: {}", fig.figure_id, chain_id));
                }
            }
        }

        // Coverage requirement: every deposit chain must be covered by at least one figure
        for chain_id in &scope_chain_ids {
            if !covered_by_figures.contains(chain_id) {
                err("DEPOSIT_CHAIN_NOT_COVERED_BY_FIGURES", format!("Deposit chain {} is not covered by any figure.chains_covered", chain_id));
            }
        }

        // Validate assets and duplicates
        validate_asset_list(&self.stolen_assets.assets, "stolen_assets.assets", registry, &mut err);
        validate_asset_list(&self.deposited_assets.assets, "deposited_assets.assets", registry, &mut err);

        // Soft checks for swaps/mismatches
        let stolen_map = asset_amount_map(&self.stolen_assets.assets);
        let deposited_map = asset_amount_map(&self.deposited_assets.assets);
        for (k, dep_amt) in deposited_map.iter() {
            if let Some(st_amt) = stolen_map.get(k) {
                if dep_amt > st_amt {
                    warn("DEPOSIT_EXCEEDS_STOLEN", format!("Deposited amount {} exceeds stolen {} for chain_id={}, symbol={}", dep_amt, st_amt, k.0, k.1));
                }
            } else {
                warn("DEPOSIT_ASSET_NOT_IN_STOLEN", format!("Deposited asset not listed in stolen_assets (swaps common): chain_id={}, symbol={}", k.0, k.1));
            }
        }

        if let Some(usd) = self.deposited_assets.total_usd_estimate {
            if !(usd > 0.0) {
                err("INVALID_USD_ESTIMATE", "deposited_assets.total_usd_estimate must be > 0".to_string());
            }
        }

        if errors.is_empty() { Ok(warnings) } else { Err(errors) }
    }
}

fn check_nonempty(val: &str, path: &str, err: &mut impl FnMut(&'static str, String)) {
    if val.trim().is_empty() {
        err("EMPTY_FIELD", format!("{} must be non-empty", path));
    }
}

fn is_yyyy_mm_dd(s: &str) -> bool {
    let bytes = s.as_bytes();
    if bytes.len() != 10 { return false; }
    bytes[4] == b'-' && bytes[7] == b'-'
        && bytes[0..4].iter().all(|c| c.is_ascii_digit())
        && bytes[5..7].iter().all(|c| c.is_ascii_digit())
        && bytes[8..10].iter().all(|c| c.is_ascii_digit())
}

fn is_symbol_valid(s: &str) -> bool {
    let len = s.len();
    if len < 2 || len > 12 { return false; }
    s.bytes().all(|c| c.is_ascii_uppercase() || c.is_ascii_digit())
}

fn validate_asset_list(
    assets: &[AssetEntry],
    path: &str,
    registry: &dyn ChainRegistry,
    err: &mut impl FnMut(&'static str, String),
) {
    let mut seen: HashSet<(String, String)> = HashSet::new();
    for (i, a) in assets.iter().enumerate() {
        if a.amount <= 0.0 {
            err("INVALID_AMOUNT", format!("{}.{} amount must be > 0", path, i));
        }
        if a.name.trim().is_empty() {
            err("EMPTY_FIELD", format!("{}.{} name must be non-empty", path, i));
        }
        if !is_symbol_valid(&a.symbol) {
            err("INVALID_SYMBOL", format!("{}.{} symbol invalid: {}", path, i, a.symbol));
        }
        if a.chain_id.trim().is_empty() {
            err("EMPTY_FIELD", format!("{}.{} chain_id must be non-empty", path, i));
        } else if registry.get(&a.chain_id).is_none() {
            err("UNSUPPORTED_CHAIN", format!("{}.{} chain_id unsupported: {}", path, i, a.chain_id));
        }

        let key = (a.chain_id.clone(), a.symbol.clone());
        if !seen.insert(key) {
            err("DUPLICATE_ASSET", format!("{} has duplicate (chain_id, symbol): ({}, {})", path, a.chain_id, a.symbol));
        }
    }
}

fn asset_amount_map(assets: &[AssetEntry]) -> HashMap<(String, String), f64> {
    let mut m = HashMap::new();
    for a in assets {
        m.insert((a.chain_id.clone(), a.symbol.clone()), a.amount);
    }
    m
}
