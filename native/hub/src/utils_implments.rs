use std::collections::HashMap;

use rinf::{DartSignal, RustSignal};

use crate::signals::{ServiceStatusInput, ServiceStatusOutput};
use cczuni::utils::status::services_status_code;
pub async fn service_status() {
    let rev = ServiceStatusInput::get_dart_signal_receiver();
    while let Some(_) = rev.recv().await {
        ServiceStatusOutput {
            data: services_status_code()
                .await
                .into_iter()
                .map(|(k, v)| (k.to_string(), v.as_str().to_string()))
                .collect::<HashMap<String, String>>(),
        }
        .send_signal_to_dart();
    }
}
