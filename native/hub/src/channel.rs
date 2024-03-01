use crate::{
    checkin::impl_generate_termviews,
    messages::{checkin::TermsDataJsonOutput, common::RustCallChannel},
};

pub async fn handle_channel() {
    let mut rev = RustCallChannel::get_dart_signal_receiver();
    while let Some(dart_signal) = rev.recv().await {
        match dart_signal.message.id {
            TERMVIEWS => {
                let result = impl_generate_termviews().await;
                let ok = (&result).is_ok();
                let data: String = match result {
                    Ok(data) => serde_json::to_string(&data).unwrap(),
                    Err(message) => message,
                };
                TermsDataJsonOutput { ok, data }.send_signal_to_dart(None);
            }
            _ => (),
        }
    }
}

const TERMVIEWS: i32 = 1;
