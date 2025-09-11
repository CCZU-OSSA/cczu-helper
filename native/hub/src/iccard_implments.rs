use cczuni::{
    base::app::AppVisitor,
    impls::{
        apps::iccard::{
            iccard::ICCardApplication,
            iccard_type::{DormArea, DormBuilding},
        },
        client::DefaultClient,
    },
};
use rinf::{DartSignal, RustSignal};

use crate::signals::{
    Building, BuildingsData, ElectricBillBuildingsQueryInput, ElectricBillBuildingsQueryOutput,
    ElectricBillRoomQueryInput, ElectricBillRoomQueryOutput,
};

pub async fn query_buildings() {
    let rev = ElectricBillBuildingsQueryInput::get_dart_signal_receiver();
    while let Some(_) = rev.recv().await {
        let client = DefaultClient::iccard("1");
        let app = client.visit::<ICCardApplication<_, _>>().await;
        let data = app.list_all_preset_buildings().await;
        match data {
            Ok(buildings) => ElectricBillBuildingsQueryOutput {
                ok: true,
                buildings: buildings
                    .into_iter()
                    .map(|e| BuildingsData {
                        area: e.area.area,
                        areaid: e.aid,
                        buildings: e
                            .buildingtab
                            .into_iter()
                            .map(|b| Building {
                                building: b.building,
                                buildingid: b.buildingid,
                            })
                            .collect(),
                    })
                    .collect(),
                error: None,
            }
            .send_signal_to_dart(),
            Err(err) => ElectricBillBuildingsQueryOutput {
                ok: false,
                buildings: vec![],
                error: Some(err.to_string()),
            }
            .send_signal_to_dart(),
        }
    }
}

pub async fn query_room() {
    let rev = ElectricBillRoomQueryInput::get_dart_signal_receiver();
    while let Some(signal) = rev.recv().await {
        let message = signal.message;

        let client = DefaultClient::iccard("1");
        let app = client.visit::<ICCardApplication<_, _>>().await;
        let data = app
            .query_electricity_bill(
                DormArea {
                    name: message.area,
                    id: message.areaid,
                },
                DormBuilding {
                    building: message.building,
                    buildingid: message.buildingid,
                },
                &message.room,
            )
            .await;

        if let Err(err) = data {
            ElectricBillRoomQueryOutput {
                ok: true,
                remain: String::new(),
                error: Some(err.to_string()),
                uniqueid: message.uniqueid,
            }
            .send_signal_to_dart();
        } else {
            ElectricBillRoomQueryOutput {
                ok: true,
                remain: data.map(|e| e.errmsg).unwrap_or_default(),
                error: None,
                uniqueid: message.uniqueid,
            }
            .send_signal_to_dart();
        }
    }
}
