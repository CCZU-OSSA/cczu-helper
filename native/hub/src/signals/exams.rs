use rinf::{DartSignal, RustSignal, SignalPiece};
use serde::{Deserialize, Serialize};

use crate::signals::AccountData;

#[derive(Deserialize, DartSignal)]
pub struct WeChatExamsInput {
    pub account: AccountData,
    pub term: String,
}

#[derive(Serialize, RustSignal)]
pub struct WeChatExamsOutput {
    pub ok: bool,
    pub data: Vec<WeChatExamData>,
    pub error: Option<String>,
}

#[derive(Serialize, SignalPiece)]
pub struct WeChatExamData {
    pub name: String,
    pub location: String,
    pub date: String,
}
