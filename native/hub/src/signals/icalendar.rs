use super::AccountData;
use rinf::{DartSignal, RustSignal};
use serde::{Deserialize, Serialize};

#[derive(Deserialize, DartSignal)]
pub struct ICalendarInput {
    pub firstweekdate: String,
    pub reminder: Option<i32>,
    pub account: AccountData,
}

#[derive(Serialize, RustSignal)]
pub struct ICalendarOutput {
    pub ok: bool,
    pub data: String,
}
#[derive(Deserialize, DartSignal)]
pub struct ICalendarWxInput {
    pub firstweekdate: String,
    pub reminder: Option<i32>,
    pub account: AccountData,
    pub term: Option<String>,
}

#[derive(Deserialize, DartSignal)]
pub struct WeChatTermsInput;

#[derive(Serialize, RustSignal)]
pub struct WeChatTermsOutput {
    pub ok: bool,
    pub terms: Vec<String>,
}