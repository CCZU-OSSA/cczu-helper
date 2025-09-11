use rinf::{DartSignal, RustSignal, SignalPiece};
use serde::{Deserialize, Serialize};

#[derive(Deserialize, DartSignal)]
pub struct ElectricBillBuildingsQueryInput;

#[derive(Serialize, RustSignal)]
pub struct ElectricBillBuildingsQueryOutput {
    pub ok: bool,
    pub buildings: Vec<BuildingsData>,
    pub error: Option<String>,
}

#[derive(Serialize, SignalPiece)]
pub struct BuildingsData {
    pub area: String,
    pub areaid: String,
    pub buildings: Vec<Building>,
}

#[derive(Serialize, SignalPiece)]
pub struct Building {
    pub building: String,
    pub buildingid: String,
}

#[derive(Deserialize, DartSignal)]
pub struct ElectricBillRoomQueryInput {
    pub areaid: String,
    pub area: String,
    pub buildingid: String,
    pub building: String,
    pub room: String,
    pub uniqueid: String,
}

#[derive(Serialize, RustSignal)]
pub struct ElectricBillRoomQueryOutput {
    pub ok: bool,
    pub remain: String,
    pub error: Option<String>,
    pub uniqueid: String,
}
