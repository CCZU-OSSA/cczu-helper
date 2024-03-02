use cczu_ical_rs::{
    ical::{get_reminder, ICal},
    user::UserClient,
};

use crate::typedata::ICalendarGenerateData;

pub async fn impl_generate_ical(data: ICalendarGenerateData) -> Result<String, String> {
    let user = data.account;
    let client = UserClient::new(&user.username, &user.password);
    if let Err(message) = client.login().await {
        return Err(message);
    };

    match client.get_classlist().await {
        Ok(v) => Ok(ICal::new(data.firstweekdate, v)
            .to_ical(get_reminder(&data.reminder))
            .to_string()),
        Err(e) => Err(e),
    }
}
