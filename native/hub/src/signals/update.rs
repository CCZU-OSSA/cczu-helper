use rinf::{DartSignal, RustSignal, SignalPiece};
use serde::{Deserialize, Serialize};

#[derive(Deserialize, DartSignal)]
pub struct GetVersionInput;

#[derive(Serialize, RustSignal)]
pub struct GetVersionOutput {
    pub ok: bool,
    pub data: Option<VersionInfo>,
    pub error: Option<String>,
}

#[derive(Serialize, SignalPiece)]
pub struct VersionInfo {
    pub tag_name: String,
    pub name: String,
    pub body: String,
    pub assets: Vec<AssetInfo>,
}
#[derive(Serialize, SignalPiece)]
pub struct AssetInfo {
    pub name: String,
    pub browser_download_url: String,
    pub size: i32,
}
