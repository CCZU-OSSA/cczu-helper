use std::collections::HashMap;

use rinf::{DartSignal, RustSignal};
use serde::{Deserialize, Serialize};
#[derive(Deserialize, DartSignal)]
pub struct ServiceStatusInput;

#[derive(Serialize, RustSignal)]
pub struct ServiceStatusOutput {
    pub data: HashMap<String, String>,
}
