use super::AccountData;
use rinf::{DartSignal, RustSignal};
use serde::{Deserialize, Serialize};
#[derive(Deserialize, DartSignal)]
pub struct LabDurationUserInput {
    pub account: AccountData,
    pub count: i32,
}

#[derive(Serialize, RustSignal)]
pub struct LabDurationUserOutput {
    pub ok: bool,
    pub error: Option<String>,
}
