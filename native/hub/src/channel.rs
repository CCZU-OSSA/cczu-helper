use crate::{
    implments::{
        impl_check_update, impl_generate_ical, impl_generate_termviews, impl_get_grades,
        impl_login_wifi,
    },
    messages::common::{DartReceiveChannel, RustCallChannel},
};
use serde::Serialize;
use serde_json::{from_str, to_string};

pub async fn handle_channel() {
    let mut rev = RustCallChannel::get_dart_signal_receiver();
    while let Some(dart_signal) = rev.recv().await {
        let message = dart_signal.message;
        let id = message.id;
        let data = message.data;
        match id {
            TERMVIEWS => impl_generate_termviews().await.handle(),
            LOGINWIFI => impl_login_wifi(from_str(&data).unwrap()).await.handle(),
            GENERATE_ICALENDAR => impl_generate_ical(from_str(&data).unwrap())
                .await
                .handle_raw(),
            CHECK_UPDATE => impl_check_update().await.handle_raw(),
            GET_GRADES => impl_get_grades(from_str(&data).unwrap()).await.handle(),
            _ => (),
        }
    }
}

pub trait ResultChannelHandler {
    fn handle(&self);
}

pub trait StringResultChannelHandler {
    fn handle_raw(&self);
}

impl<T> ResultChannelHandler for Result<T, String>
where
    T: Serialize + Clone,
{
    fn handle(&self) {
        match self.clone() {
            Ok(data) => DartReceiveChannel {
                ok: true,
                data: to_string(&data).unwrap(),
            }
            .send_signal_to_dart(None),
            Err(message) => DartReceiveChannel {
                ok: false,
                data: message,
            }
            .send_signal_to_dart(None),
        }
    }
}

impl StringResultChannelHandler for Result<String, String> {
    fn handle_raw(&self) {
        match self.clone() {
            Ok(data) => DartReceiveChannel { ok: true, data }.send_signal_to_dart(None),
            Err(message) => DartReceiveChannel {
                ok: false,
                data: message,
            }
            .send_signal_to_dart(None),
        }
    }
}

const TERMVIEWS: i32 = 1;
const LOGINWIFI: i32 = 2;
const GENERATE_ICALENDAR: i32 = 3;
const CHECK_UPDATE: i32 = 4;
const GET_GRADES: i32 = 5;
