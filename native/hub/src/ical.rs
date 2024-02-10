use cczu_ical_rs::{
    ical::{get_reminder, ICal},
    user::UserClient,
};

use crate::messages::ical::{ICalJsonCallback, UserDataSyncInput};

pub async fn generate_ical() {
    let mut rev = UserDataSyncInput::get_dart_signal_receiver();
    while let Some(dart_signal) = rev.recv().await {
        impl_generate_ical(dart_signal.message)
            .await
            .send_signal_to_dart(None);
    }
}

async fn impl_generate_ical(user: UserDataSyncInput) -> ICalJsonCallback {
    let client = UserClient::new(&user.username, &user.password);
    if let Err(message) = client.login().await {
        return ICalJsonCallback {
            ok: false,
            data: message,
        };
    };
    match client.get_classlist().await {
        Ok(cl) => {
            let mut ical = ICal::new(user.firstweekdate, cl);
            ICalJsonCallback {
                ok: true,
                data: ical
                    .to_ical(get_reminder(user.reminder.as_str()))
                    .to_string(),
            }
        }
        Err(e) => ICalJsonCallback { ok: false, data: e },
    }
}
