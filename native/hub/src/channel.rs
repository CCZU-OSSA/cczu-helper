use crate::{
    checkin::impl_generate_termviews,
    icalendar::impl_generate_ical,
    messages::common::{DartReceiveChannel, RustCallChannel},
    typedata::ICalendarGenerateData,
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
            LOGINWIFI => {}
            GENERATE_ICALENDAR => {
                let data: ICalendarGenerateData = from_str(&data).unwrap();
                impl_generate_ical(data).await.handle()
            }
            _ => (),
        }
    }
}

pub trait ResultChannelHandler<T> {
    fn handle(&self);
}

impl<T> ResultChannelHandler<T> for Result<T, String>
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

const TERMVIEWS: i32 = 1;
const LOGINWIFI: i32 = 2;
const GENERATE_ICALENDAR: i32 = 3;
