use rinf::{DartSignal, RustSignal, SignalPiece};
use serde::{Deserialize, Serialize};

#[derive(Deserialize, SignalPiece)]
pub struct AccountData {
    pub user: String,
    pub password: String,
}

#[derive(Deserialize, DartSignal)]
pub struct EDUAccountLoginInput {
    pub account: AccountData,
}
#[derive(Deserialize, DartSignal)]
pub struct SSOAccountLoginInput {
    pub account: AccountData,
}

#[derive(Serialize, RustSignal)]
pub struct AccountLoginCallback {
    pub ok: bool,
    pub error: Option<String>,
}
