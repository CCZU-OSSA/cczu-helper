use rinf::{DartSignal, RustSignal};
use serde::{Deserialize, Serialize};

#[derive(Deserialize, DartSignal)]
pub struct CMCCAccountGenerateInput {
    pub phone: String,
}

#[derive(Serialize, RustSignal)]
pub struct CMCCAccountGenerateOutput {
    pub account: String,
}
